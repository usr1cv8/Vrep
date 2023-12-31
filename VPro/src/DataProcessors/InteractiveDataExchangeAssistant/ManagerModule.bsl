#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region ServiceProgramInterface

// For internal use.
//
Procedure RunAutomaticDataMapping(Parameters, TemporaryStorageAddress) Export
	
	PutToTempStorage(
		ResultOfAutomaticMappingData(Parameters.InfobaseNode, Parameters.ExchangeMessageFileName, Parameters.TemporaryExchangeMessagesDirectoryName,
		Parameters.CheckVersionDifference), TemporaryStorageAddress
	);
		
EndProcedure

// For internal use.
//
Function ResultOfAutomaticMappingData(Val Correspondent, Val ExchangeMessageFileName, Val TemporaryExchangeMessagesDirectoryName, CheckVersionDifference) Export
	
	// Execute automatic data mapping received from correspondent.
	// Get mapping statistics.
	
	SetPrivilegedMode(True);
	
	DataExchangeServer.InitializeVersionDifferencesCheckParameters(CheckVersionDifference);
	
	InteractiveDataExchangeAssistant = DataProcessors.InteractiveDataExchangeAssistant.Create();
	InteractiveDataExchangeAssistant.InfobaseNode = Correspondent;
	InteractiveDataExchangeAssistant.ExchangeMessageFileName = ExchangeMessageFileName;
	InteractiveDataExchangeAssistant.TemporaryExchangeMessagesDirectoryName = TemporaryExchangeMessagesDirectoryName;
	InteractiveDataExchangeAssistant.ExchangePlanName = DataExchangeReUse.GetExchangePlanName(Correspondent);
	InteractiveDataExchangeAssistant.ExchangeMessageTransportKind = Undefined;
	
	// Execute exchange message analysis.
	Cancel = False;
	InteractiveDataExchangeAssistant.RunExchangeMessageAnalysis(Cancel);
	If Cancel Then
		If SessionParameters.VersionsDifferenceErrorOnReceivingData.IsError Then
			Return SessionParameters.VersionsDifferenceErrorOnReceivingData;
		Else
			Raise StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en='Cannot import data from ""%1"" (data analysis step).';ru='Не удалось загрузить данные из ""%1"" (этап анализа данных).';vi='Không thể kết nhập dữ liệu từ ""%1"" (giai đoạn phân tích dữ liệu).'"),
				String(Correspondent));
		EndIf;
	EndIf;
	
	// Execute automatic mapping and receive mapping statistics.
	Cancel = False;
	InteractiveDataExchangeAssistant.RunAutomaticMappingByDefaultAndGetMappingStats(Cancel);
	If Cancel Then
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en='Cannot import data from ""%1"" (automatic data mapping step).';ru='Не удалось загрузить данные из ""%1"" (этап автоматического сопоставления данных).';vi='Không thể kết nhập dữ liệu từ ""%1"" (giai đoạn tự động so sánh dữ liệu).'"),
			String(Correspondent));
	EndIf;
	
	TableOfInformationStatistics = InteractiveDataExchangeAssistant.TableOfInformationStatistics();
	
	Result = New Structure;
	Result.Insert("StatisticsInformation", TableOfInformationStatistics);
	Result.Insert("AllDataMapped", AllDataMapped(TableOfInformationStatistics));
	Result.Insert("StatisticsIsEmpty", TableOfInformationStatistics.Count() = 0);
	
	Return Result;
EndFunction

// For an internal use.
//
Procedure ExecuteDataImport(Parameters, TemporaryStorageAddress) Export
	
	DataExchangeServer.ExecuteDataExchangeForInfobaseNodeOverFileOrString(
		Parameters.InfobaseNode,
		Parameters.ExchangeMessageFileName,
		Enums.ActionsAtExchange.DataImport
	);
EndProcedure

// For an internal use.
//
Function AllDataMapped(StatisticsInformation) Export
	
	Return (StatisticsInformation.FindRows(New Structure("PictureIndex", 1)).Count() = 0);
	
EndFunction

#EndRegion

#EndIf
