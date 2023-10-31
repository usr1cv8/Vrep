
////////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ И ФУНКЦИИ ОБЩЕГО НАЗНАЧЕНИЯ

// Процедура заполняет реквизиты формы из параметров.
//
&AtServer
Procedure FillAttributesByParameters()
	
	If Parameters.Property("RepetitionFactorOFDay") Then
		RepetitionFactorOFDay = Parameters.RepetitionFactorOFDay;
		RepetitionFactorOFDayOnOpen = Parameters.RepetitionFactorOFDay;
	EndIf;
	
EndProcedure // ПроверитьМодифицированностьФормы()

// Процедура проверяет модифицированность формы.
//
&AtClient
Procedure CheckIfFormWasModified()
	
	WereMadeChanges = False;
	
	ChangesRepetitionFactorOFDay = RepetitionFactorOFDayOnOpen <> RepetitionFactorOFDay;
	
	If ChangesRepetitionFactorOFDay Then
		WereMadeChanges = True;
	EndIf;
	
EndProcedure // ПроверитьМодифицированностьФормы()

////////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ - ОБРАБОТЧИКИ СОБЫТИЙ ФОРМЫ

// Процедура - обработчик события ПриСозданииНаСервере формы.
// В процедуре осуществляется
// - инициализация параметров формы.
//
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	FillAttributesByParameters();
	
	WereMadeChanges = False;
	
EndProcedure // ПриСозданииНаСервере()

////////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ - ДЕЙСТВИЯ КОМАНДНЫХ ПАНЕЛЕЙ ФОРМЫ

// Процедура - обработчик события нажатия кнопки ОК.
//
&AtClient
Procedure CommandOK(Command)
	
	CheckIfFormWasModified();
	
	StructureOfFormAttributes = New Structure;
	
	StructureOfFormAttributes.Insert("WereMadeChanges", WereMadeChanges);
	
	StructureOfFormAttributes.Insert("RepetitionFactorOFDay", RepetitionFactorOFDay);
	
	Close(StructureOfFormAttributes);
	
EndProcedure // КомандаОК()
