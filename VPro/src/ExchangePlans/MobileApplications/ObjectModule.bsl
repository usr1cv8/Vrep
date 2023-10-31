#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure BeforeWrite(Cancel)
	
	If Roles.Find(Enums.RolesOfMobileApplication.FullRights, "Role") <> Undefined Then
		Roles.Clear();
		AppendRoleInTable(Enums.RolesOfMobileApplication.BasicRights);
		AppendRoleInTable(Enums.RolesOfMobileApplication.MovementMoneyViewAndEdit);
		AppendRoleInTable(Enums.RolesOfMobileApplication.GoodsMovementsViewAndEdit);
		AppendRoleInTable(Enums.RolesOfMobileApplication.ProductionViewAndEdit);
		AppendRoleInTable(Enums.RolesOfMobileApplication.OrdersViewAndEdit);
		AppendRoleInTable(Enums.RolesOfMobileApplication.CounterpartiesViewAndEdit);
		AppendRoleInTable(Enums.RolesOfMobileApplication.NomenclatureViewAndEdit);
		AppendRoleInTable(Enums.RolesOfMobileApplication.MoneyMovementReportView);
		AppendRoleInTable(Enums.RolesOfMobileApplication.ReportStockBalancesView);
		AppendRoleInTable(Enums.RolesOfMobileApplication.ReportDebtsView);
		AppendRoleInTable(Enums.RolesOfMobileApplication.ReportSalesView);
		AppendRoleInTable(Enums.RolesOfMobileApplication.ReadingBalancesOfBilling);
		AppendRoleInTable(Enums.RolesOfMobileApplication.ReadingBalanceGoods);
		AppendRoleInTable(Enums.RolesOfMobileApplication.RetailViewAndEdit);
		AppendRoleInTable(Enums.RolesOfMobileApplication.CompanyInfoViewAndEdit);
	EndIf;
	
EndProcedure

Procedure AppendRoleInTable(Role) Export
	
	NewRow = Roles.Add();
	NewRow.Role = Role;
	
EndProcedure

Procedure SetRolesByProfile(ProfileForSetup) Export
	
	Profile = ProfileForSetup;
	
	Roles.Clear();
	AppendRoleInTable(Enums.RolesOfMobileApplication.BasicRights);
	
	If ProfileForSetup = Enums.MobileApplicationProfiles.Owner Then
		AppendRoleInTable(Enums.RolesOfMobileApplication.CounterpartiesViewAndEdit);
		AppendRoleInTable(Enums.RolesOfMobileApplication.NomenclatureViewAndEdit);
		AppendRoleInTable(Enums.RolesOfMobileApplication.OrdersViewAndEdit);
		AppendRoleInTable(Enums.RolesOfMobileApplication.MovementMoneyViewAndEdit);
		AppendRoleInTable(Enums.RolesOfMobileApplication.GoodsMovementsViewAndEdit);
		AppendRoleInTable(Enums.RolesOfMobileApplication.ProductionViewAndEdit);
		AppendRoleInTable(Enums.RolesOfMobileApplication.MoneyMovementReportView);
		AppendRoleInTable(Enums.RolesOfMobileApplication.ReportStockBalancesView);
		AppendRoleInTable(Enums.RolesOfMobileApplication.ReportSalesView);
		AppendRoleInTable(Enums.RolesOfMobileApplication.ReportDebtsView);
		AppendRoleInTable(Enums.RolesOfMobileApplication.RetailViewAndEdit);
		AppendRoleInTable(Enums.RolesOfMobileApplication.CompanyInfoViewAndEdit);
	ElsIf ProfileForSetup = Enums.MobileApplicationProfiles.Seller Then
		AppendRoleInTable(Enums.RolesOfMobileApplication.CounterpartiesViewAndEdit);
		AppendRoleInTable(Enums.RolesOfMobileApplication.NomenclatureOnlyView);
		AppendRoleInTable(Enums.RolesOfMobileApplication.OrdersViewAndEdit);
		AppendRoleInTable(Enums.RolesOfMobileApplication.MovementMoneyViewAndEdit);
		AppendRoleInTable(Enums.RolesOfMobileApplication.GoodsMovementsViewAndEdit);
		AppendRoleInTable(Enums.RolesOfMobileApplication.MoneyMovementReportView);
		AppendRoleInTable(Enums.RolesOfMobileApplication.ReportStockBalancesView);
		AppendRoleInTable(Enums.RolesOfMobileApplication.ReportSalesView);
		AppendRoleInTable(Enums.RolesOfMobileApplication.CompanyInfoOnlyView);
	ElsIf ProfileForSetup = Enums.MobileApplicationProfiles.SalesRepresentative Then
		AppendRoleInTable(Enums.RolesOfMobileApplication.CounterpartiesViewAndEdit);
		AppendRoleInTable(Enums.RolesOfMobileApplication.NomenclatureOnlyView);
		AppendRoleInTable(Enums.RolesOfMobileApplication.OrdersViewAndEdit);
		AppendRoleInTable(Enums.RolesOfMobileApplication.MovementMoneyViewAndEdit);
		AppendRoleInTable(Enums.RolesOfMobileApplication.GoodsMovementsViewAndEdit);
		AppendRoleInTable(Enums.RolesOfMobileApplication.MoneyMovementReportView);
		AppendRoleInTable(Enums.RolesOfMobileApplication.ReportStockBalancesView);
		AppendRoleInTable(Enums.RolesOfMobileApplication.ReportDebtsView);
		AppendRoleInTable(Enums.RolesOfMobileApplication.CompanyInfoOnlyView);
	ElsIf ProfileForSetup = Enums.MobileApplicationProfiles.ServiceEngineer Then
		AppendRoleInTable(Enums.RolesOfMobileApplication.CounterpartiesOnlyView);
		AppendRoleInTable(Enums.RolesOfMobileApplication.NomenclatureOnlyView);
		AppendRoleInTable(Enums.RolesOfMobileApplication.OrdersViewAndEdit);
		AppendRoleInTable(Enums.RolesOfMobileApplication.MovementMoneyViewAndEdit);
		AppendRoleInTable(Enums.RolesOfMobileApplication.GoodsMovementsViewAndEdit);
		AppendRoleInTable(Enums.RolesOfMobileApplication.MoneyMovementReportView);
		AppendRoleInTable(Enums.RolesOfMobileApplication.ReportStockBalancesView);
		AppendRoleInTable(Enums.RolesOfMobileApplication.CompanyInfoOnlyView);
	ElsIf ProfileForSetup = Enums.MobileApplicationProfiles.RetailPoint Then
		AppendRoleInTable(Enums.RolesOfMobileApplication.NomenclatureOnlyView);
		AppendRoleInTable(Enums.RolesOfMobileApplication.ReportSalesView);
		AppendRoleInTable(Enums.RolesOfMobileApplication.RetailViewAndEdit);
		AppendRoleInTable(Enums.RolesOfMobileApplication.CompanyInfoOnlyView);
	ElsIf ProfileForSetup = Enums.MobileApplicationProfiles.MobileTelephony Then
		AppendRoleInTable(Enums.RolesOfMobileApplication.CounterpartiesOnlyView);
	EndIf;
	
EndProcedure

#EndIf