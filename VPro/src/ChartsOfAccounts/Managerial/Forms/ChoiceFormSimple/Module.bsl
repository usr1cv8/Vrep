
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	FilterItem = List.SettingsComposer.FixedSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.LeftValue = New DataCompositionField("Ref");
	FilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	FilterItem.Use = True;
	
	IncludeCostOfOther = False;
	IncludeInIncomeOther = False;
	
	// To display other expenses together with the principal expenses.
	If Parameters.Property("IncludeCostOfOther") Then
		IncludeCostOfOther = Parameters.IncludeCostOfOther;
	EndIf;
	
	// To display other income together with the principal one.
	If Parameters.Property("IncludeInIncomeOther") Then
		IncludeInIncomeOther = Parameters.IncludeInIncomeOther;
	EndIf;
	
	// To change the form header.
	If Parameters.Property("InvoiceHeader") Then
		Title = Parameters.InvoiceHeader;
	EndIf;
	
	// To change the form header.
	If Parameters.Property("ExcludePredefinedAccount") Then
		ExcludePredefinedAccount = Parameters.ExcludePredefinedAccount;
	EndIf;
	
	If Parameters.Property("CurrentRow")
	   AND ValueIsFilled(Parameters.CurrentRow)
	   AND TypeOf(Parameters.CurrentRow) = Type("ChartOfAccountsRef.Managerial")
	   AND Parameters.Property("Filter")
	   AND Parameters.Filter.Property("TypeOfAccount") Then // if the account is already selected.
		AddHierarchy(Parameters.Filter.TypeOfAccount, Parameters.CurrentRow.TypeOfAccount);
		FilterItem.RightValue = Parameters.CurrentRow; // to exclude blinking at filter setting.
	ElsIf Parameters.Property("Filter")
			AND Parameters.Filter.Property("TypeOfAccount") Then // if the account isn't selected.
		AddHierarchy(Parameters.Filter.TypeOfAccount);
		FilterItem.RightValue = ChartsOfAccounts.Managerial.EmptyRef(); // to exclude blinking at filter setting.
	Else
		AddHierarchy();
		FilterItem.RightValue = ChartsOfAccounts.Managerial.EmptyRef();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	Items.Hierarchy.CurrentRow = CurHierarchyRow;
	
EndProcedure

#EndRegion

#Region FormItemsEventsHandlers

&AtClient
Procedure HierarchyOnActivateRow(Item)
	
	If Items.Hierarchy.CurrentData <> Undefined
	   AND CurHierarchy <> Items.Hierarchy.CurrentData.Value Then
		SetFilterOnClient(Items.Hierarchy.CurrentData.Value);
		CurHierarchy = Items.Hierarchy.CurrentData.Value;
	EndIf;
	
EndProcedure

#EndRegion

#Region ServiceProceduresAndFunctions

&AtServer
Procedure AddHierarchy(GLAccountsTypes = Undefined, TypeOfAccount = Undefined)
	
	UseSubsystemProduction = Constants.FunctionalOptionUseSubsystemProduction.Get();
	
	Ct = 0;
	CurHierarchyRow = 0;
	
	If TypeOf(GLAccountsTypes) = Type("FixedArray") Then
		For Each CurAccountType IN GLAccountsTypes Do
			InvoiceHeader = "";
			If CurAccountType = Enums.GLAccountsTypes.Expenses Then
				InvoiceHeader = NStr("en='Expenses allocated to the financial result (Indirect)';ru='Расходы, распределяемые на финансовый результат (Косвенные)';vi='Chi phí được phân bổ theo kết quả hoạt động kinh doanh (Gián tiếp)'");
			ElsIf CurAccountType = Enums.GLAccountsTypes.OtherExpenses Then
				InvoiceHeader = NStr("en='Other expenses allocated to the financial result';ru='Прочие расходы, распределяемые на финансовый результат';vi='Chi khác được phân bổ theo kết quả kinh doanh'");
			ElsIf  CurAccountType = Enums.GLAccountsTypes.Incomings Then
				InvoiceHeader = NStr("en='Income allocated to the financial result';ru='Доходы, распределяемые на финансовый результат';vi='Thu nhập được phân bổ cho kết quả kinh doanh'");
			ElsIf CurAccountType = Enums.GLAccountsTypes.OtherIncome Then
				InvoiceHeader = NStr("en='Other income allocated to the financial result';ru='Прочие доходы, распределяемые на финансовый результат';vi='Thu nhập khác được phân bổ theo kết quả kinh doanh'");
			ElsIf CurAccountType = Enums.GLAccountsTypes.Debitors Then
				InvoiceHeader = NStr("en='Other debtors (debt to us)';ru='Прочие дебиторы (задолженность перед нами)';vi='Nợ phải thu khác'");
			ElsIf CurAccountType = Enums.GLAccountsTypes.Creditors Then
				InvoiceHeader = NStr("en='Other creditors (our debt)';ru='Прочие кредиторы (наша задолженность)';vi='Nợ phải trả khác'");
			ElsIf CurAccountType = Enums.GLAccountsTypes.CashAssets Then
				InvoiceHeader = NStr("en='Funds transfer';ru='Перемещения денег';vi='Chuyển tiền nội bộ'");
			ElsIf CurAccountType = Enums.GLAccountsTypes.LongtermObligations Then
				InvoiceHeader = NStr("en='Long-term liabilities';ru='Долгосрочные обязательства';vi='Phải trả dài hạn'");
			ElsIf CurAccountType = Enums.GLAccountsTypes.Capital Then
				InvoiceHeader = NStr("en='Capital';ru='Капитал';vi='Vốn'");
			ElsIf CurAccountType = Enums.GLAccountsTypes.Loans Then
				InvoiceHeader = NStr("en='Credits and Loans';ru='Кредиты и займы';vi='Vay và cho vay'");
			ElsIf CurAccountType = Enums.GLAccountsTypes.UnfinishedProduction Then
				InvoiceHeader = NStr("en='Expenses related to product release (Direct)';ru='Затраты, относящиеся к выпуску продукции (Прямые)';vi='Chi phí liên quan đến việc xuất xưởng thành phẩm (Trực tiếp)'");
			ElsIf CurAccountType = Enums.GLAccountsTypes.IndirectExpenses Then
				InvoiceHeader = NStr("en='Costs allocated to product release cost (Indirect)';ru='Затраты, распределяемые на себестоимость выпуска продукции (Косвенные)';vi='Chi phí được phân bổ cho giá thành xuất xưởng thành phẩm (Gián tiếp)'");
			ElsIf CurAccountType = Enums.GLAccountsTypes.OtherCurrentAssets Then
				InvoiceHeader = NStr("en='Other Current Assets';ru='Прочие оборотные активы';vi='Tài sản ngắn hạn khác'");
			EndIf;
			If (UseSubsystemProduction
				  OR (CurAccountType <> Enums.GLAccountsTypes.UnfinishedProduction
					   AND CurAccountType <> Enums.GLAccountsTypes.IndirectExpenses))
			   AND (NOT IncludeCostOfOther
				  OR (IncludeCostOfOther
					   AND CurAccountType <> Enums.GLAccountsTypes.OtherExpenses))
			   AND (NOT IncludeInIncomeOther
				  OR (IncludeInIncomeOther
					   AND CurAccountType <> Enums.GLAccountsTypes.OtherIncome)) Then // adding hierarchy if the filter corresponds to conditions.
				Hierarchy.Add(CurAccountType, InvoiceHeader);
				If CurAccountType = TypeOfAccount
					OR (IncludeCostOfOther AND TypeOfAccount = Enums.GLAccountsTypes.OtherExpenses AND CurAccountType = Enums.GLAccountsTypes.Expenses)
					OR (IncludeInIncomeOther AND TypeOfAccount = Enums.GLAccountsTypes.OtherIncome AND CurAccountType = Enums.GLAccountsTypes.Incomings) Then
					CurHierarchyRow = Ct;
				EndIf;
				Ct = Ct + 1;
			EndIf;
		EndDo;
	ElsIf ValueIsFilled(GLAccountsTypes) Then
		Hierarchy.Add(GLAccountsTypes);
		CurHierarchyRow = 0;
	Else
		For Ct = 0 To Enums.GLAccountsTypes.Count() - 1 Do
			Hierarchy.Add(Enums.GLAccountsTypes[Ct]);
		EndDo;
		CurHierarchyRow = 0;
	EndIf;
	
	For Ct = 0 To Hierarchy.Count() - 1 Do
		Hierarchy[Ct].Picture = PictureLib.Folder;
	EndDo;
	
EndProcedure

&AtClient
Procedure SetFilterOnClient(TypeOfAccount = Undefined)
	
	List.SettingsComposer.FixedSettings.Filter.Items.Clear();
	
	If ExcludePredefinedAccount Then
		
		FilterList = New ValueList(); // Accounts matching accumulation registers shall be excluded from the filter for other operations.
		FilterList.Add(PredefinedValue("ChartOfAccounts.Managerial.Bank"));
		FilterList.Add(PredefinedValue("ChartOfAccounts.Managerial.PettyCash"));
		FilterList.Add(PredefinedValue("ChartOfAccounts.Managerial.Taxes"));
		FilterList.Add(PredefinedValue("ChartOfAccounts.Managerial.TaxesToRefund"));
		FilterList.Add(PredefinedValue("ChartOfAccounts.Managerial.SettlementsByAdvancesIssued"));
		FilterList.Add(PredefinedValue("ChartOfAccounts.Managerial.AccountsByAdvancesReceived"));
		FilterList.Add(PredefinedValue("ChartOfAccounts.Managerial.AccountsReceivable"));
		FilterList.Add(PredefinedValue("ChartOfAccounts.Managerial.AccountsPayable"));
		FilterList.Add(PredefinedValue("ChartOfAccounts.Managerial.AdvanceHolderPayments"));
		FilterList.Add(PredefinedValue("ChartOfAccounts.Managerial.OverrunOfAdvanceHolders"));
		FilterList.Add(PredefinedValue("ChartOfAccounts.Managerial.PayrollPaymentsOnPay"));
		
		FilterItem = List.SettingsComposer.FixedSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
		FilterItem.LeftValue = New DataCompositionField("Ref");
		FilterItem.ComparisonType = DataCompositionComparisonType.NotInList;
		FilterItem.Use = True;
		FilterItem.RightValue = FilterList;
		
	EndIf;
	
	If ValueIsFilled(TypeOfAccount) Then
		
		FilterItem = List.SettingsComposer.FixedSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
		FilterItem.LeftValue = New DataCompositionField("TypeOfAccount");
		FilterItem.ComparisonType = DataCompositionComparisonType.Equal;
		FilterItem.Use = True;
		
		If TypeOfAccount = PredefinedValue("Enum.GLAccountsTypes.Expenses")
		   AND IncludeCostOfOther = True Then
			FilterList = New ValueList();
			FilterList.Add(PredefinedValue("Enum.GLAccountsTypes.Expenses"));
			FilterList.Add(PredefinedValue("Enum.GLAccountsTypes.OtherExpenses"));
			FilterItem.ComparisonType = DataCompositionComparisonType.InList;
			FilterItem.RightValue = FilterList;
		ElsIf TypeOfAccount = PredefinedValue("Enum.GLAccountsTypes.Incomings")
		   AND IncludeInIncomeOther = True Then
			FilterList = New ValueList();
			FilterList.Add(PredefinedValue("Enum.GLAccountsTypes.Incomings"));
			FilterList.Add(PredefinedValue("Enum.GLAccountsTypes.OtherIncome"));
			FilterItem.ComparisonType = DataCompositionComparisonType.InList;
			FilterItem.RightValue = FilterList;
		Else
			FilterItem.RightValue = TypeOfAccount;
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion
