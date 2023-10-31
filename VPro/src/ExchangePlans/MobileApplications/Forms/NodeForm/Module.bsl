
&AtClient
Procedure ProfileOnChange(Item)
	
	SetRolesByProfile();
	
EndProcedure

&AtServer
Procedure SetRolesByProfile()
	
	If Object.Profile = PredefinedValue("Enum.MobileApplicationProfiles.Owner") Then
		Counterparties = PredefinedValue("Enum.RoleValue.Enabled");
		Nomenclature = PredefinedValue("Enum.RoleValue.Enabled");
		Orders = PredefinedValue("Enum.RoleValue.Enabled");
		MovementMoney = PredefinedValue("Enum.RoleValue.Enabled");
		GoodsMovements = PredefinedValue("Enum.RoleValue.Enabled");
		MoneyMovementReport = PredefinedValue("Enum.RoleValue.Enabled");
		ReportStockBalances = PredefinedValue("Enum.RoleValue.Enabled");
		ReportSales = PredefinedValue("Enum.RoleValue.Enabled");
		ReportDebts = PredefinedValue("Enum.RoleValue.Enabled");
		TaxCalendar = PredefinedValue("Enum.RoleValue.Enabled");
		Production = PredefinedValue("Enum.RoleValue.Enabled");
		Retail = PredefinedValue("Enum.RoleValue.Enabled");
		CompanyInfo = PredefinedValue("Enum.RoleValue.Enabled");
		Object.ByResponsible = False;
	ElsIf Object.Profile = PredefinedValue("Enum.MobileApplicationProfiles.Seller") Then
		Counterparties = PredefinedValue("Enum.RoleValue.Enabled");
		Nomenclature = PredefinedValue("Enum.RoleValue.ViewOnly");
		Orders = PredefinedValue("Enum.RoleValue.Disabled");
		MovementMoney = PredefinedValue("Enum.RoleValue.Enabled");
		GoodsMovements = PredefinedValue("Enum.RoleValue.Enabled");
		MoneyMovementReport = PredefinedValue("Enum.RoleValue.Enabled");
		ReportStockBalances = PredefinedValue("Enum.RoleValue.Enabled");
		ReportSales = PredefinedValue("Enum.RoleValue.Enabled");
		ReportDebts = PredefinedValue("Enum.RoleValue.Disabled");
		TaxCalendar = PredefinedValue("Enum.RoleValue.Disabled");
		Production = PredefinedValue("Enum.RoleValue.Disabled");
		Retail = PredefinedValue("Enum.RoleValue.Disabled");
		CompanyInfo = PredefinedValue("Enum.RoleValue.ViewOnly");
		Object.ByResponsible = True;
	ElsIf Object.Profile = PredefinedValue("Enum.MobileApplicationProfiles.SalesRepresentative") Then
		Counterparties = PredefinedValue("Enum.RoleValue.Enabled");
		Nomenclature = PredefinedValue("Enum.RoleValue.ViewOnly");
		Orders = PredefinedValue("Enum.RoleValue.Enabled");
		MovementMoney = PredefinedValue("Enum.RoleValue.Enabled");
		GoodsMovements = PredefinedValue("Enum.RoleValue.Enabled");
		MoneyMovementReport = PredefinedValue("Enum.RoleValue.Enabled");
		ReportStockBalances = PredefinedValue("Enum.RoleValue.Enabled");
		ReportSales = PredefinedValue("Enum.RoleValue.Disabled");
		ReportDebts = PredefinedValue("Enum.RoleValue.Enabled");
		TaxCalendar = PredefinedValue("Enum.RoleValue.Disabled");
		Production = PredefinedValue("Enum.RoleValue.Disabled");
		Retail = PredefinedValue("Enum.RoleValue.Disabled");
		CompanyInfo = PredefinedValue("Enum.RoleValue.ViewOnly");
		Object.ByResponsible = True;
	ElsIf Object.Profile = PredefinedValue("Enum.MobileApplicationProfiles.ServiceEngineer") Then
		Counterparties = PredefinedValue("Enum.RoleValue.ViewOnly");
		Nomenclature = PredefinedValue("Enum.RoleValue.ViewOnly");
		Orders = PredefinedValue("Enum.RoleValue.Enabled");
		MovementMoney = PredefinedValue("Enum.RoleValue.Enabled");
		GoodsMovements = PredefinedValue("Enum.RoleValue.Enabled");
		MoneyMovementReport = PredefinedValue("Enum.RoleValue.Enabled");
		ReportStockBalances = PredefinedValue("Enum.RoleValue.Enabled");
		ReportSales = PredefinedValue("Enum.RoleValue.Disabled");
		ReportDebts = PredefinedValue("Enum.RoleValue.Disabled");
		TaxCalendar = PredefinedValue("Enum.RoleValue.Disabled");
		Production = PredefinedValue("Enum.RoleValue.Disabled");
		Retail = PredefinedValue("Enum.RoleValue.Disabled");
		CompanyInfo = PredefinedValue("Enum.RoleValue.ViewOnly");
		Object.ByResponsible = True;
	ElsIf Object.Profile = PredefinedValue("Enum.MobileApplicationProfiles.RetailPoint") Then
		Counterparties = PredefinedValue("Enum.RoleValue.Disabled");
		Nomenclature = PredefinedValue("Enum.RoleValue.ViewOnly");
		Orders = PredefinedValue("Enum.RoleValue.Disabled");
		MovementMoney = PredefinedValue("Enum.RoleValue.Disabled");
		GoodsMovements = PredefinedValue("Enum.RoleValue.Disabled");
		MoneyMovementReport = PredefinedValue("Enum.RoleValue.Disabled");
		ReportStockBalances = PredefinedValue("Enum.RoleValue.Disabled");
		ReportSales = PredefinedValue("Enum.RoleValue.Enabled");
		ReportDebts = PredefinedValue("Enum.RoleValue.Disabled");
		TaxCalendar = PredefinedValue("Enum.RoleValue.Disabled");
		Production = PredefinedValue("Enum.RoleValue.Disabled");
		Retail = PredefinedValue("Enum.RoleValue.Enabled");
		CompanyInfo = PredefinedValue("Enum.RoleValue.ViewOnly");
		Object.ByResponsible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure SetProfileDetailSetting()
	
	Object.Profile = PredefinedValue("Enum.MobileApplicationProfiles.DetailedSetting");
	
EndProcedure

&AtClient
Procedure AppendRoleInTable(Role)
	
	NewRow = Object.Roles.Add();
	NewRow.Role = Role;
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	Object.Roles.Clear();
	AppendRoleInTable(PredefinedValue("Enum.RolesOfMobileApplication.BasicRights"));
	If Counterparties = PredefinedValue("Enum.RoleValue.Enabled") Then
		AppendRoleInTable(PredefinedValue("Enum.RolesOfMobileApplication.CounterpartiesViewAndEdit"));
	ElsIf Counterparties = PredefinedValue("Enum.RoleValue.ViewOnly") Then
		AppendRoleInTable(PredefinedValue("Enum.RolesOfMobileApplication.CounterpartiesOnlyView"));
	EndIf;
	If Nomenclature = PredefinedValue("Enum.RoleValue.Enabled") Then
		AppendRoleInTable(PredefinedValue("Enum.RolesOfMobileApplication.NomenclatureViewAndEdit"));
	ElsIf Nomenclature = PredefinedValue("Enum.RoleValue.ViewOnly") Then
		AppendRoleInTable(PredefinedValue("Enum.RolesOfMobileApplication.NomenclatureOnlyView"));
	EndIf;
	If Orders = PredefinedValue("Enum.RoleValue.Enabled") Then
		AppendRoleInTable(PredefinedValue("Enum.RolesOfMobileApplication.OrdersViewAndEdit"));
	ElsIf Orders = PredefinedValue("Enum.RoleValue.ViewOnly") Then
		AppendRoleInTable(PredefinedValue("Enum.RolesOfMobileApplication.OrdersOnlyView"));
	EndIf;
	If MovementMoney = PredefinedValue("Enum.RoleValue.Enabled") Then
		AppendRoleInTable(PredefinedValue("Enum.RolesOfMobileApplication.MovementMoneyViewAndEdit"));
	ElsIf MovementMoney = PredefinedValue("Enum.RoleValue.ViewOnly") Then
		AppendRoleInTable(PredefinedValue("Enum.RolesOfMobileApplication.MovementMoneyOnlyView"));
	EndIf;
	If GoodsMovements = PredefinedValue("Enum.RoleValue.Enabled") Then
		AppendRoleInTable(PredefinedValue("Enum.RolesOfMobileApplication.GoodsMovementsViewAndEdit"));
	ElsIf GoodsMovements = PredefinedValue("Enum.RoleValue.ViewOnly") Then
		AppendRoleInTable(PredefinedValue("Enum.RolesOfMobileApplication.GoodsMovementsOnlyView"));
	EndIf;
	If Production = PredefinedValue("Enum.RoleValue.Enabled") Then
		AppendRoleInTable(PredefinedValue("Enum.RolesOfMobileApplication.ProductionViewAndEdit"));
	ElsIf Production = PredefinedValue("Enum.RoleValue.ViewOnly") Then
		AppendRoleInTable(PredefinedValue("Enum.RolesOfMobileApplication.ProductionOnlyView"));
	EndIf;
	If MoneyMovementReport = PredefinedValue("Enum.RoleValue.Enabled") Then
		AppendRoleInTable(PredefinedValue("Enum.RolesOfMobileApplication.MoneyMovementReportView"));
	EndIf;
	If ReportStockBalances = PredefinedValue("Enum.RoleValue.Enabled") Then
		AppendRoleInTable(PredefinedValue("Enum.RolesOfMobileApplication.ReportStockBalancesView"));
	EndIf;
	If ReportSales = PredefinedValue("Enum.RoleValue.Enabled") Then
		AppendRoleInTable(PredefinedValue("Enum.RolesOfMobileApplication.ReportSalesView"));
	EndIf;
	If ReportDebts = PredefinedValue("Enum.RoleValue.Enabled") Then
		AppendRoleInTable(PredefinedValue("Enum.RolesOfMobileApplication.ReportDebtsView"));
	EndIf;
	If TaxCalendar = PredefinedValue("Enum.RoleValue.Enabled") Then
		AppendRoleInTable(PredefinedValue("Enum.RolesOfMobileApplication.TaxCalendar"));
	EndIf;
	If Retail = PredefinedValue("Enum.RoleValue.Enabled") Then
		AppendRoleInTable(PredefinedValue("Enum.RolesOfMobileApplication.RetailViewAndEdit"));
	ElsIf Retail = PredefinedValue("Enum.RoleValue.ViewOnly") Then
		AppendRoleInTable(PredefinedValue("Enum.RolesOfMobileApplication.RetailOnlyView"));
	EndIf;
	If CompanyInfo = PredefinedValue("Enum.RoleValue.Enabled") Then
		AppendRoleInTable(PredefinedValue("Enum.RolesOfMobileApplication.CompanyInfoViewAndEdit"));
	ElsIf CompanyInfo = PredefinedValue("Enum.RoleValue.ViewOnly") Then
		AppendRoleInTable(PredefinedValue("Enum.RolesOfMobileApplication.CompanyInfoOnlyView"));
	EndIf;
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Counterparties = Enums.RoleValue.Disabled;
	Nomenclature = Enums.RoleValue.Disabled;
	Orders = Enums.RoleValue.Disabled;
	MovementMoney = Enums.RoleValue.Disabled;
	GoodsMovements = Enums.RoleValue.Disabled;
	Production = Enums.RoleValue.Disabled;
	MoneyMovementReport = Enums.RoleValue.Disabled;
	ReportStockBalances = Enums.RoleValue.Disabled;
	ReportSales = Enums.RoleValue.Disabled;
	ReportDebts = Enums.RoleValue.Disabled;
	TaxCalendar = Enums.RoleValue.Disabled;
	Retail = Enums.RoleValue.Disabled;
	CompanyInfo = Enums.RoleValue.Disabled;
	
	RoleFullRightsIsAvaliable = False;
	
	For Each CurRow In Object.Roles Do
		
		If CurRow.Role = Enums.RolesOfMobileApplication.FullRights Then
			RoleFullRightsIsAvaliable = True;
			Break;
		ElsIf CurRow.Role = Enums.RolesOfMobileApplication.CounterpartiesViewAndEdit Then
			Counterparties = Enums.RoleValue.Enabled;
		ElsIf CurRow.Role = Enums.RolesOfMobileApplication.CounterpartiesOnlyView Then
			Counterparties = Enums.RoleValue.ViewOnly;
		ElsIf CurRow.Role = Enums.RolesOfMobileApplication.NomenclatureViewAndEdit Then
			Nomenclature = Enums.RoleValue.Enabled;
		ElsIf CurRow.Role = Enums.RolesOfMobileApplication.NomenclatureOnlyView Then
			Nomenclature = Enums.RoleValue.ViewOnly;
		ElsIf CurRow.Role = Enums.RolesOfMobileApplication.OrdersViewAndEdit Then
			Orders = Enums.RoleValue.Enabled;
		ElsIf CurRow.Role = Enums.RolesOfMobileApplication.OrdersOnlyView Then
			Orders = Enums.RoleValue.ViewOnly;
		ElsIf CurRow.Role = Enums.RolesOfMobileApplication.MovementMoneyViewAndEdit Then
			MovementMoney = Enums.RoleValue.Enabled;
		ElsIf CurRow.Role = Enums.RolesOfMobileApplication.MovementMoneyOnlyView Then
			MovementMoney = Enums.RoleValue.ViewOnly;
		ElsIf CurRow.Role = Enums.RolesOfMobileApplication.GoodsMovementsViewAndEdit Then
			GoodsMovements = Enums.RoleValue.Enabled;
		ElsIf CurRow.Role = Enums.RolesOfMobileApplication.GoodsMovementsOnlyView Then
			GoodsMovements = Enums.RoleValue.ViewOnly;
		ElsIf CurRow.Role = Enums.RolesOfMobileApplication.ProductionViewAndEdit Then
			Production = Enums.RoleValue.Enabled;
		ElsIf CurRow.Role = Enums.RolesOfMobileApplication.ProductionOnlyView Then
			Production = Enums.RoleValue.Enabled;
		ElsIf CurRow.Role = Enums.RolesOfMobileApplication.MoneyMovementReportView Then
			MoneyMovementReport = Enums.RoleValue.Enabled;
		ElsIf CurRow.Role = Enums.RolesOfMobileApplication.ReportStockBalancesView Then
			ReportStockBalances = Enums.RoleValue.Enabled;
		ElsIf CurRow.Role = Enums.RolesOfMobileApplication.ReportSalesView Then
			ReportSales = Enums.RoleValue.Enabled;
		ElsIf CurRow.Role = Enums.RolesOfMobileApplication.ReportDebtsView Then
			ReportDebts = Enums.RoleValue.Enabled;
		ElsIf CurRow.Role = Enums.RolesOfMobileApplication.TaxCalendar Then
			TaxCalendar = Enums.RoleValue.Enabled;
		ElsIf CurRow.Role = Enums.RolesOfMobileApplication.RetailViewAndEdit Then
			Retail = Enums.RoleValue.Enabled;
		ElsIf CurRow.Role = Enums.RolesOfMobileApplication.RetailOnlyView Then
			Retail = Enums.RoleValue.ViewOnly;
		ElsIf CurRow.Role = Enums.RolesOfMobileApplication.CompanyInfoViewAndEdit Then
			CompanyInfo = Enums.RoleValue.Enabled;
		ElsIf CurRow.Role = Enums.RolesOfMobileApplication.CompanyInfoOnlyView Then
			CompanyInfo = Enums.RoleValue.ViewOnly;
		EndIf;
		
	EndDo;
	
	If RoleFullRightsIsAvaliable Then
		Object.Profile = Enums.MobileApplicationProfiles.Owner;
		SetRolesByProfile();
	EndIf;
	
	If Object.Roles.Count() = 0 Then
		Items.Roles.Visible = False;
	Else
		Items.Roles.Visible = True;
	EndIf;
		
	If NOT ExchangeMobileApplicationCommon.IsVersionForProduction(Object.Ref) Then
		Items.Production.Visible = False;
	EndIf;
	
	If ExchangeMobileApplicationCommon.IsVersionForRetail(Object.Ref) Then
		Items.Profile.ChoiceList.Add(Enums.MobileApplicationProfiles.RetailPoint);
	Else
		Items.Retail.Visible = False;
		Items.CashCR.Visible = False;
		Items.CompanyInfo.Visible = False;
	EndIf;
	
	If Object.Profile = Enums.MobileApplicationProfiles.MobileTelephony Then
		Items.Profile.ReadOnly = True;
		Items.CompanyInfo.Visible = False;
		Items.Nomenclature.Visible = False;
		Items.Orders.Visible = False;
		Items.MovementMoney.Visible = False;
		Items.GoodsMovements.Visible = False;
		Items.Production.Visible = False;
		Items.Retail.Visible = False;
		Items.ReportStockBalances.Visible = False;
		Items.MoneyMovementReport.Visible = False;
		Items.ReportSales.Visible = False;
		Items.ReportDebts.Visible = False;
		Items.TaxCalendar.Visible = False;
		Items.CashCR.Visible = False;
		Items.CashCRStructuralUnit.Visible = False;
		Items.ForAllCashRegisters.Visible = False;
		Items.ByResponsible.Visible = False;
		Items.Profile.ChoiceList.Add(Enums.MobileApplicationProfiles.MobileTelephony);
	EndIf;
	
	Items.Profile.ChoiceList.Add(Enums.MobileApplicationProfiles.DetailedSetting);
	
EndProcedure

&AtClient
Procedure TaxCalendarOnChange(Item)
	
	SetProfileDetailSetting();
	
EndProcedure

&AtClient
Procedure ProductionOnChange(Item)
	
	SetProfileDetailSetting();
	
EndProcedure

&AtClient
Procedure RetailOnChange(Item)
	
	SetProfileDetailSetting();
	
EndProcedure

&AtClient
Procedure CompanyInfoOnChange(Item)
	
	SetProfileDetailSetting();
	
EndProcedure

&AtClient
Procedure CounterpartiesOnChange(Item)
	
	SetProfileDetailSetting();
	
EndProcedure

&AtClient
Procedure NomenclatureOnChange(Item)
	
	SetProfileDetailSetting();
	
EndProcedure

&AtClient
Procedure OrdersOnChange(Item)
	
	SetProfileDetailSetting();
	
EndProcedure

&AtClient
Procedure MovementMoneyOnChange(Item)
	
	SetProfileDetailSetting();
	
EndProcedure

&AtClient
Procedure GoodsMovementsOnChange(Item)
	
	SetProfileDetailSetting();
	
EndProcedure

&AtClient
Procedure ReportStockBalancesOnChange(Item)
	
	SetProfileDetailSetting();
	
EndProcedure

&AtClient
Procedure MoneyMovementReportOnChange(Item)
	
	SetProfileDetailSetting();
	
EndProcedure

&AtClient
Procedure ReportSalesOnChange(Item)
	
	SetProfileDetailSetting();
	
EndProcedure

&AtClient
Procedure ReportDebtsOnChange(Item)
	
	SetProfileDetailSetting();
	
EndProcedure