
////////////////////////////////////////////////////////////////////////////////
// PROCEDURE - FORM EVENT HANDLERS

&AtServer
//  Procedure - form event handler "OnCreateAtServer".
//
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not Parameters.Property("Order") Then
		
		Message = New UserMessage();
		Message.Text = NStr("en='It is possible to generate the report only from the ""Customer order"" document.';ru='Вызов отчета возможен только из документа ""Заказ покупателя""!';vi='Chỉ có thể gọi ra báo cáo từ chứng từ ""Đơn hàng của khách""!'");
		Message.Message();
		
		Cancel = True;
		Return;
		
	EndIf;
	
	DCSParameters = Report.SettingsComposer.Settings.DataParameters;
	DCSParameter = DCSParameters.Items.Find("Order");
	
	If DCSParameter <> Undefined Then
		DCSParameters.SetParameterValue("Order", Parameters.Order);
	EndIf;
	
	ComposeResult();
	
EndProcedure // OnCreateAtServer()
// 
