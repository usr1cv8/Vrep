#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region ProgramInterface

#Region ForCallsFromOtherSubsystems

// Определяет список команд заполнения.
//
// Parameters:
//   FillCommands - ValueTable - Таблица с командами заполнения. Для изменения.
//       See описание 1 параметра процедуры ЗаполнениеОбъектовПереопределяемый.ПередДобавлениемКомандЗаполнения().
//   Parameters - Structure - Вспомогательные параметры. Для чтения.
//       See описание 2 параметра процедуры ЗаполнениеОбъектовПереопределяемый.ПередДобавлениемКомандЗаполнения().
//
Procedure AddFillCommands(FillCommands, Parameters) Export
	
EndProcedure

#EndRegion

#EndRegion

#Region PrintInterface

// Заполняет список команд печати.
// 
// Parameters:
//   PrintCommands - ValueTable - состав полей See в функции УправлениеПечатью.СоздатьКоллекциюКомандПечати
//
Procedure AddPrintCommands(PrintCommands) Export
	
	
	
EndProcedure

#EndRegion

#EndIf