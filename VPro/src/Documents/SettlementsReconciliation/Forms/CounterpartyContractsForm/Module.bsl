

///////////////////////////////////////////////////////////////////////////////
// PROCEDURE - FORM EVENT HANDLERS

&AtServer
// Procedure - OnCreateAtServer event handler.
//
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	StandardProcessing = False;
	
	Counterparty = Parameters.Counterparty;
	CounterpartyContracts.Load(Parameters.CounterpartyContracts.Unload());
	
	CheckContractsFilling = False;
	
EndProcedure // OnCreateAtServer()

&AtClient
// Procedure - event handler BeforeClose form.
//
Procedure BeforeClose(Cancel, StandardProcessing)
	
	If CheckContractsFilling Then
	
		For Each Contract IN CounterpartyContracts Do
			
			If Not ValueIsFilled(Contract.Contract) Then
				
				MessageText = NStr("en='There are rows with a blank counterparty contract in the table';ru='В таблице присутствуют строки с незаполненным договором контрагента';vi='Trong bảng có dòng có hợp đồng đối tác chưa điền'");
				CommonUseClientServer.MessageToUser(MessageText, , , , Cancel);
				Break;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure // BeforeClose()


//////////////////////////////////////////////////////////////////////////////////
// COMMAND HANDLERS

&AtClient
// Procedure command handler OK
//
Procedure OK(Command)
	
	CheckContractsFilling = True;
	Modified = False;
	Close(New Structure("CounterpartyContracts", CounterpartyContracts));
	
EndProcedure // Ok()

&AtClient
// Procedure command handler Cancel
//
Procedure Cancel(Command)
	
	CheckContractsFilling = False;
	Modified = False;
	Close();
	
EndProcedure // Cancel()

&AtClient
// Procedure command handler SelectCheckboxes
//
Procedure CheckAll(Command)
	
	For Each ListRow IN CounterpartyContracts Do
		
		ListRow.Select = True;
		
	EndDo;
	
EndProcedure // SelectCheckboxes()

&AtClient
// Procedure command handler SelectCheckboxes
//
Procedure UncheckAll(Command)
	
	For Each ListRow IN CounterpartyContracts Do
		
		ListRow.Select = False;
		
	EndDo;
	
EndProcedure // ClearCheckboxes()
// 
