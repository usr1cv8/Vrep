#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region ServiceProceduresAndFunctions

// Shifts the limits of totals.
Procedure RunCommand(CommandParameters, StorageAddress) Export
	SetPrivilegedMode(True);
	TotalsAndAggregateManagementService.SetTotalsPeriod();
	Result = New Structure;
	StandardSubsystemsClientServer.DisplayNotification(
		Result,
		NStr("en='Application optimization';ru='Оптимизация программы';vi='Tối ưu hóa chương trình'"),
		NStr("en='completed';ru='успешно завершена';vi='đã kết thúc thành công'"),
		PictureLib.Successfully32);
	PutToTempStorage(Result, StorageAddress);
EndProcedure

#EndRegion

#EndIf
