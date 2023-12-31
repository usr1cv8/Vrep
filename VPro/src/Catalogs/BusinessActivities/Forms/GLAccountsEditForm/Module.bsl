
////////////////////////////////////////////////////////////////////////////////
// GENERAL PURPOSE PROCEDURES AND FUNCTIONS

// Function checks account change option.
//
&AtServer
Function DenialChangeGLAccounts(BusinessActivity)
	
	Query = New Query(
	"SELECT TOP 1
	|	IncomeAndExpenses.Period,
	|	IncomeAndExpenses.Recorder,
	|	IncomeAndExpenses.LineNumber,
	|	IncomeAndExpenses.Active,
	|	IncomeAndExpenses.Company,
	|	IncomeAndExpenses.StructuralUnit,
	|	IncomeAndExpenses.BusinessActivity,
	|	IncomeAndExpenses.CustomerOrder,
	|	IncomeAndExpenses.GLAccount,
	|	IncomeAndExpenses.AmountIncome,
	|	IncomeAndExpenses.AmountExpense,
	|	IncomeAndExpenses.ContentOfAccountingRecord
	|FROM
	|	AccumulationRegister.IncomeAndExpenses AS IncomeAndExpenses
	|WHERE
	|	IncomeAndExpenses.BusinessActivity = &BusinessActivity");
	
	Query.SetParameter("BusinessActivity", BusinessActivity);
	
	Result = Query.Execute();
	
	Return Not Result.IsEmpty();
	
EndFunction // DenialChangeRevenueGLAccountFromSales()

////////////////////////////////////////////////////////////////////////////////
// PROCEDURE - FORM EVENT HANDLERS

// Procedure - event handler OnCreateAtServer of the form.
//
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	GLAccountRevenueFromSales = Parameters.GLAccountRevenueFromSales;
	GLAccountCostOfSales = Parameters.GLAccountCostOfSales;
	ProfitGLAccount = Parameters.ProfitGLAccount;
	BusinessActivity = Parameters.Ref;
	
	If DenialChangeGLAccounts(BusinessActivity) Then
		Items.GLAccountsGroup.ToolTip = NStr("en='There is income or expenses for this area in the infobase. Cannot change GL accounts of sales revenue.';ru='В базе есть доходы или расходы по этому направлению деятельности! Изменение счета учета выручки от продаж запрещено!';vi='Trong cơ sở có thu nhập và chi phí theo hướng hoạt động này! Cấm thay đổi tài khoản kế toán doanh thu bán hàng!'");
		Items.GLAccountsGroup.Enabled = False;
		Items.Default.Visible = False;
	EndIf;
	
	If Parameters.Ref = Catalogs.BusinessActivities.Other Then
		
		NewParameter = New ChoiceParameter("Filter.TypeOfAccount", Enums.GLAccountsTypes.OtherIncome);
		NewArray = New Array();
		NewArray.Add(NewParameter);
		NewParameters = New FixedArray(NewArray);
		Items.GLAccountRevenueFromSales.ChoiceParameters = NewParameters;
		
		NewParameter = New ChoiceParameter("Filter.TypeOfAccount", Enums.GLAccountsTypes.OtherExpenses);
		NewArray = New Array();
		NewArray.Add(NewParameter);
		NewParameters = New FixedArray(NewArray);
		Items.GLAccountCostOfSales.ChoiceParameters = NewParameters;
		
	Else
		
		NewParameter = New ChoiceParameter("Filter.TypeOfAccount", Enums.GLAccountsTypes.Incomings);
		NewArray = New Array();
		NewArray.Add(NewParameter);
		NewParameters = New FixedArray(NewArray);
		Items.GLAccountRevenueFromSales.ChoiceParameters = NewParameters;
		
		NewParameter = New ChoiceParameter("Filter.TypeOfAccount", Enums.GLAccountsTypes.CostOfGoodsSold);
		NewArray = New Array();
		NewArray.Add(NewParameter);
		NewParameters = New FixedArray(NewArray);
		Items.GLAccountCostOfSales.ChoiceParameters = NewParameters;
		
	EndIf;
	
EndProcedure // OnCreateAtServer()

////////////////////////////////////////////////////////////////////////////////
// PROCEDURE - ACTIONS OF THE FORM COMMAND PANELS

// Procedure - command click handler Default.
//
&AtClient
Procedure Default(Command)
	
	GLAccountRevenueFromSales = PredefinedValue("ChartOfAccounts.Managerial.SalesRevenue");
	GLAccountCostOfSales = PredefinedValue("ChartOfAccounts.Managerial.CostOfGoodsSold");
	ProfitGLAccount = PredefinedValue("ChartOfAccounts.Managerial.ProfitsAndLossesWithoutProfitTax");
	NotifyAccountChange();
	
EndProcedure // Default()

&AtClient
Procedure GLAccountRevenueFromSalesOnChange(Item)
	
	If Not ValueIsFilled(GLAccountRevenueFromSales) Then
		GLAccountRevenueFromSales = PredefinedValue("ChartOfAccounts.Managerial.SalesRevenue");
	EndIf;
	NotifyAccountChange();
	
EndProcedure

&AtClient
Procedure GLAccountCostOfSalesOnChange(Item)
	
	If Not ValueIsFilled(GLAccountCostOfSales) Then
		GLAccountCostOfSales = PredefinedValue("ChartOfAccounts.Managerial.CostOfGoodsSold");
	EndIf;
	NotifyAccountChange();
	
EndProcedure

&AtClient
Procedure ProfitGLAccountOnChange(Item)
	
	If Not ValueIsFilled(ProfitGLAccount) Then
		ProfitGLAccount = PredefinedValue("ChartOfAccounts.Managerial.ProfitsAndLossesWithoutProfitTax");
	EndIf;
	NotifyAccountChange();
	
EndProcedure

&AtClient
Procedure NotifyAccountChange()
	
	ParameterStructure = New Structure(
		"GLAccountRevenueFromSales, GLAccountCostOfSales, ProfitGLAccount",
		GLAccountRevenueFromSales, GLAccountCostOfSales, ProfitGLAccount
	);
	
	Notify("ActivityAccountsChanged", ParameterStructure);
	
EndProcedure
