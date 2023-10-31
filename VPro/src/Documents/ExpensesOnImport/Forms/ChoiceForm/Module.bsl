
&AtServer
// Процедура - обработчик события ПриСозданииНаСервере.
//
Procedure OnCreateAtServer(cancel, StandardProcessing)
	
	// Установим формат для текущей даты: ДФ=Ч:мм
	SmallBusinessServer.SetDesignDateColumn(List);
	
EndProcedure // ПриСозданииНаСервере()