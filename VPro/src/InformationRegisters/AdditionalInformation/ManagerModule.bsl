
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region ProgramInterface

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.AccessManagement

// See AccessManagementOverridable.OnFillListWithAccessRestriction.
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowReadChange
	|WHERE
	|	ValueAllowed(Property)";
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#EndIf
