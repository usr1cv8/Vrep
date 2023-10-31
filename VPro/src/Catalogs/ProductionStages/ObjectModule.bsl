
Procedure ПередЗаписью(Отказ)
	
	If Отказ ИЛИ ОбменДанными.Загрузка Then
		Return;
	EndIf; 
	
	If Ссылка=ПредопределенноеЗначение("Справочник.ProductionStages.ProductionComplete") И ПометкаУдаления Then
		ПометкаУдаления = False;
	EndIf; 
	
EndProcedure
