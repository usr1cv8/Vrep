
////////////////////////////////////////////////////////////////////////////////
// GENERAL PURPOSE PROCEDURES AND FUNCTIONS

// Function checks GL account change option.
//
&AtServer
Function CancelGLAccountChange(Ref)
	
	Query = New Query(
	"SELECT
	|	RetailReportPaymentWithPaymentCards.Ref,
	|	RetailReportPaymentWithPaymentCards.LineNumber,
	|	RetailReportPaymentWithPaymentCards.POSTerminal,
	|	RetailReportPaymentWithPaymentCards.ChargeCardKind,
	|	RetailReportPaymentWithPaymentCards.ChargeCardNo,
	|	RetailReportPaymentWithPaymentCards.Amount
	|FROM
	|	Document.RetailReport.PaymentWithPaymentCards AS RetailReportPaymentWithPaymentCards
	|WHERE
	|	RetailReportPaymentWithPaymentCards.Ref.Posted = True
	|	AND RetailReportPaymentWithPaymentCards.POSTerminal = &POSTerminal");
	
	Query.SetParameter("POSTerminal", ?(ValueIsFilled(Ref), Ref, Undefined));
	
	Result = Query.Execute();
	
	Return Not Result.IsEmpty();
	
EndFunction // CancelGLAccountChange()

////////////////////////////////////////////////////////////////////////////////
// PROCEDURE - FORM EVENT HANDLERS

// Procedure - event handler OnCreateAtServer of the form.
//
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	GLAccount = Parameters.GLAccount;
	
	If CancelGLAccountChange(Parameters.Ref) Then
		Items.GLAccountsGroup.ToolTip = NStr("en='Records are registered for this POS terminal in the infobase. Cannot change the GL account.';ru='В базе есть движения по этому эквайринговому терминалу! Изменение счета учета запрещено!';vi='Trong cơ sở có bản ghi kết chuyển theo thiết bị thanh toán thẻ này! Cấm thay đổi tài khoản kế toán!'");
		Items.GLAccountsGroup.Enabled = False;
	EndIf;
	
EndProcedure // OnCreateAtServer()

////////////////////////////////////////////////////////////////////////////////
// PROCEDURE - ACTIONS OF THE FORM COMMAND PANELS

// Procedure - command click handler Default.
//
&AtClient
Procedure Default(Command)
	
	GLAccount = PredefinedValue("ChartOfAccounts.Managerial.TransfersInProcess");
	NotifyAboutSettlementAccountChange();
	
EndProcedure // Default()

&AtClient
Procedure GLAccountOnChange(Item)
	
	If Not ValueIsFilled(GLAccount) Then
		GLAccount = PredefinedValue("ChartOfAccounts.Managerial.TransfersInProcess");
	EndIf;
	
	NotifyAboutSettlementAccountChange();
	
EndProcedure

&AtClient
Procedure NotifyAboutSettlementAccountChange()
	
	ParameterStructure = New Structure(
		"GLAccount",
		GLAccount
	);
	
	Notify("GLAccountChangedPOSTerminals", ParameterStructure);
	
EndProcedure
