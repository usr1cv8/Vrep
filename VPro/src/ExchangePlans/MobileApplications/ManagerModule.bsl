#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

// The function should return:
// True, if the correspondent supports the exchange scenario in which the current IB operates in local mode, and the correspondent in the service model. 
// 
// False - if such an exchange script is not supported.
//
Function ReporterInModelService() Export
	
	Return False;
	
EndFunction // ReporterInModelService()

// Gets the array of exchange nodes used in the exchange settings.
//
Function GetUsedUsePlansExchange() Export
	
	Query = New Query(
		"SELECT ALLOWED
		|	MobileApplications.Ref AS Ref
		|FROM
		|	ExchangePlan.MobileApplications AS MobileApplications
		|WHERE
		|	NOT MobileApplications.DeletionMark
		|	AND MobileApplications.Ref <> &ThisNode");
		
	Query.SetParameter("ThisNode", ExchangePlans.MobileApplications.ThisNode());
	
	Return Query.Execute().Unload().UnloadColumn("Ref");
	
EndFunction

// Returns the name of the configuration family. 
// Used to support exchanges with modified configurations in the service.
//
Function SourceConfigurationName() Export
	
	Return "УправлениеНебольшойФирмой";
	
EndFunction // SourceConfigurationName()

// Allows you to override the default exchange plan settings.
// For the default settings, see Data ExchangeServer.SettingsPlanExchangePlan Default
// 
// Parameters:
//	Template - Structure - Contains default settings
//
// Sample:
//	Settings.WarningSpecifiedVersionRulesExchange = False;
Procedure DefineSettings(Template) Export
	
	
	
EndProcedure // DefineSettings()

#EndIf