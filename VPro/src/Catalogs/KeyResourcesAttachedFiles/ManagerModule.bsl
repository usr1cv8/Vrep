///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, ООО 1С-Софт
// Все права защищены. Эта программа и сопроводительные материалы предоставляются 
// в соответствии с условиями лицензии Attribution 4.0 International (CC BY 4.0)
// Текст лицензии доступен по ссылке:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region ProgramInterface

#Region ForCallsFromOtherSubsystems

// СтандартныеПодсистемы.ГрупповоеИзменениеОбъектов

// Возвращает реквизиты объекта, которые разрешается редактировать
// с помощью обработки группового изменения реквизитов.
//
// Returns:
//  Array - список имен реквизитов объекта.
Function EditedAttributesInGroupDataProcessing() Export
	
	Return FileOperations.EditedAttributesInGroupDataProcessing();
	
EndFunction

// Конец СтандартныеПодсистемы.ГрупповоеИзменениеОбъектов

// СтандартныеПодсистемы.УправлениеДоступом

// See AccessManagementOverridable.OnFillListWithAccessRestriction.
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.ПоВладельцуБезЗаписиКлючейДоступа = False;
	Restriction.Text =
	"AllowReadChange
	|WHERE
	|	ЧтениеОбъектаРазрешено(FileOwner)";
	
EndProcedure

// Конец СтандартныеПодсистемы.УправлениеДоступом

#EndRegion

#EndRegion

#EndIf
