////////////////////////////////////////////////////////////////////////////////
// Data exchange subsystem
//
////////////////////////////////////////////////////////////////////////////////

#Region ServiceProceduresAndFunctions

// Checks the necessity to update the database configuration in the subordinate node.
//
Procedure CheckSubordinatedNodeConfigurationUpdateNecessity() Export
	
	UpdateNeeded = StandardSubsystemsClientReUse.ClientWorkParameters().SiteConfigurationUpdateRequiredRIB;
	CheckUpdateNecessity(UpdateNeeded);
	
EndProcedure

// Checks the necessity to update the database configuration in the subordinate node on start.
//
Procedure CheckSubordinatedNodeConfigurationUpdateNecessityOnStart() Export
	
	UpdateNeeded = StandardSubsystemsClientReUse.ClientWorkParametersOnStart().SiteConfigurationUpdateRequiredRIB;
	CheckUpdateNecessity(UpdateNeeded);
	
EndProcedure

Procedure CheckUpdateNecessity(SiteConfigurationUpdateRequiredRIB)
	
	If SiteConfigurationUpdateRequiredRIB Then
		Explanation = NStr("en='Application update received from ""%1""."
"It is necessary to install the application update after which the data synchronization will be continued.';ru='Получено обновление программы из ""%1""."
"Необходимо установить обновление программы, после чего синхронизация данных будет продолжена.';vi='Đã nhận bản cập nhật chương trình từ ""%1""."
"Cần cài đặt bản cập nhật chương trình, sau đó tiếp tục đồng bộ hóa dữ liệu.'");
		Explanation = StringFunctionsClientServer.SubstituteParametersInString(Explanation, StandardSubsystemsClientReUse.ClientWorkParameters().MasterNode);
		ShowUserNotification(NStr("en='Install the update';ru='Установить обновление';vi='Đặt cập nhật'"), "e1cib/app/DataProcessor.DataExchangeExecution",
			Explanation, PictureLib.Warning32);
		Notify("DataExchangeCompleted");
	EndIf;
	
	AttachIdleHandler("CheckSubordinatedNodeConfigurationUpdateNecessity", 60 * 60, True); // once an hour
	
EndProcedure

#EndRegion
