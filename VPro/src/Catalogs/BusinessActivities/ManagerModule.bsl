#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

// Event handler procedure ChoiceDataGetProcessor.
//
Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	If Parameters.Property("ProductsAndServices") Then
		
		If Not Parameters.ProductsAndServices.ExpensesGLAccount.TypeOfAccount = Enums.GLAccountsTypes.Expenses Then
			
			MessageText = NStr("en='Business area cannot be selected for this expense.';ru='Для этого расхода нельзя выбрать направление деятельности!';vi='Đối với chi phí này không thể chọn lĩnh vực hoạt động kinh doanh!'");
			SmallBusinessServer.ShowMessageAboutError(, MessageText);
			
			StandardProcessing = False;
			
		EndIf;	
		
	EndIf;	
		
	If Parameters.Property("GLExpenseAccount") Then
		
		If ValueIsFilled(Parameters.GLExpenseAccount) Then
			
			If Parameters.GLExpenseAccount.TypeOfAccount = Enums.GLAccountsTypes.OtherExpenses Then
				
				MessageText = NStr("en='Business area is not specified for the ""Other expenses"" account type.';ru='Для счета типа ""Прочие расходы"" направление деятельности не указывается!';vi='Đối với tài khoản kiểu ""Chi phí khác"" chưa chỉ ra lĩnh vực hoạt động kinh doanh!'");
				SmallBusinessServer.ShowMessageAboutError(, MessageText);
				
				StandardProcessing = False;
				
			ElsIf Parameters.GLExpenseAccount.TypeOfAccount = Enums.GLAccountsTypes.UnfinishedProduction
				  OR Parameters.GLExpenseAccount.TypeOfAccount = Enums.GLAccountsTypes.IndirectExpenses Then
				  
				MessageText = NStr("en='Business area is not specified for the ""Unfinished production"" or ""Indirect expenses"" account types.';ru='Для счета типа ""Незавершенное производство"" или ""Косвенные затраты"" направление деятельности не указывается!';vi='Đối với tài khoản kiểu ""Sản xuất dở dang"" hoặc ""Chi phí gián tiếp"" chưa chỉ ra lĩnh vực hoạt động kinh doanh!'");
				SmallBusinessServer.ShowMessageAboutError(, MessageText);
				
				StandardProcessing = False;
				
			EndIf;
			
		Else
			
			MessageText = NStr("en='Account is not selected.';ru='Не выбран счет!';vi='Chưa chọn tài khoản!'");
			SmallBusinessServer.ShowMessageAboutError(, MessageText);
			
			StandardProcessing = False;
			
		EndIf;
		
	EndIf;
	
EndProcedure // ChoiceDataGetProcessor()

#Region PrintInterface

// Fills in the list of printing commands.
// 
// Parameters:
//   PrintCommands - ValueTable - see the fields content in the PrintManagement.CreatePrintCommandsCollection function
//
Procedure AddPrintCommands(PrintCommands) Export
	
	
	
EndProcedure

// Перенесет все направления деятельности для договоров обслуживания в иерархию выбранного в настройках объекта.
//
Procedure GroupServiceContractsActivityDirections() Export
	
	Parent = Constants.BillingHeadBusinessActivity.Get();
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	CounterpartyContracts.ServiceContractBusinessActivity AS BusinessActivity
	|FROM
	|	Catalog.CounterpartyContracts AS CounterpartyContracts
	|WHERE
	|	CounterpartyContracts.IsServiceContract
	|	AND CounterpartyContracts.ServiceContractBusinessActivity <> VALUE(Catalog.BusinessActivities.EmptyRef)";
	
	SELECTION = Query.Execute().Select();
	
	BeginTransaction();
	While SELECTION.Next() Do
		
		BusinessActivityObject = SELECTION.BusinessActivity.GetObject();
		BusinessActivityObject.Parent = Parent;
		BusinessActivityObject.Write();
		
	EndDo;
	CommitTransaction();
	
EndProcedure

#EndRegion

#EndIf