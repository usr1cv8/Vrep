
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	GLAccount			= Parameters.GLAccount;
	GLExpenseAccount	= Parameters.GLExpenseAccount;
	Ref					= Parameters.Ref;
	
	If CancelEditGLAccounts(Ref) Then
		Items.GroupGLAccounts.ToolTip	= NStr("en='Records are registered for these products and services in the infobase. Cannot change the GL account.';ru='В базе есть движения по этой номенклатуре! Изменение счета учета запрещено!';vi='Trong cơ sở có bản ghi kết chuyển theo mặt hàng này! Cấm thay đổi tài khoản kế toán!'");
		Items.GroupGLAccounts.Enabled	= False;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormItemEventHandlers

&AtClient
Procedure GLAccountOnChange(Item)

	NotifyAboutChangingGLAccount();
	
EndProcedure

&AtClient
Procedure GLExpenseAccountOnChange(Item)

	NotifyAboutChangingGLAccount();
	
EndProcedure

#EndRegion

#Region ServiceProceduresAndFunctions

&AtServer
Function CancelEditGLAccounts(Ref)
	
	Query = New Query(
	"SELECT
	|	BankCharges.Period,
	|	BankCharges.Recorder,
	|	BankCharges.LineNumber,
	|	BankCharges.Active,
	|	BankCharges.Company,
	|	BankCharges.BankAccount,
	|	BankCharges.Currency,
	|	BankCharges.BankCharge,
	|	BankCharges.Item,
	|	BankCharges.Amount
	|FROM
	|	AccumulationRegister.BankCharges AS BankCharges
	|WHERE
	|	BankCharges.BankCharge = &BankCharge");
	
	Query.SetParameter("BankCharge", ?(ValueIsFilled(Ref), Ref, Undefined));
	
	Result = Query.Execute();
	
	Return Not Result.IsEmpty();
	
EndFunction // CancelEditGLAccounts()

&AtClient
Procedure NotifyAboutChangingGLAccount()
	
	ParametersStructure = New Structure(
		"GLAccount, GLExpenseAccount",
		GLAccount, GLExpenseAccount
	);
	
	Notify("GLAccountsChanged", ParametersStructure);
	
EndProcedure

#EndRegion


