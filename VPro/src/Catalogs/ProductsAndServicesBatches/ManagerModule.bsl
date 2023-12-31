#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventsHandlers

// Event handler procedure ChoiceDataGetProcessor.
//
Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	If Parameters.Filter.Property("Owner")
		AND ValueIsFilled(Parameters.Filter.Owner)
		AND Not Parameters.Filter.Owner.UseBatches Then
		
		Message = New UserMessage();
		Message.Text = NStr("en='Accounting by batches is not kept for products and services.';ru='Для номенклатуры не ведется учет по партиям!';vi='Đối với mặt hàng không tiến hành kế toán theo lô!'");
		Message.Message();
		StandardProcessing = False;
		
	EndIf;
	
EndProcedure // ChoiceDataGetProcessor()

#EndRegion

#Region PrintInterface

// Fills in the list of printing commands.
// 
// Parameters:
//   PrintCommands - ValueTable - see the fields content in the PrintManagement.CreatePrintCommandsCollection function
//
Procedure AddPrintCommands(PrintCommands) Export
	
	
	
EndProcedure

#EndRegion

#EndIf
