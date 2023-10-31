#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region ProgramInterface

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.ГрупповоеИзменениеОбъектов

// Возвращает реквизиты объекта, которые разрешается редактировать
// с помощью обработки группового изменения реквизитов.
//
// Returns:
//  Array - список имен реквизитов объекта.
Function EditedAttributesInGroupDataProcessing() Export
	
	EditableAttributes = New Array;
	EditableAttributes.Add("Parent");
	EditableAttributes.Add("DeletionMark");
	
	Return EditableAttributes;
	
EndFunction

// End StandardSubsystems.ГрупповоеИзменениеОбъектов

// StandardSubsystems.УправлениеДоступом

// See AccessManagementOverridable.OnFillListWithAccessRestriction.
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowReadChange
	|WHERE
	|	ValueAllowed(Owner)
	|	OR NOT Owner.ThisIsAdditionalInformation";
	
EndProcedure

// End StandardSubsystems.УправлениеДоступом

#EndRegion

#EndRegion

#EndIf

#Region EventsHandlers

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)

EndProcedure

#EndRegion

