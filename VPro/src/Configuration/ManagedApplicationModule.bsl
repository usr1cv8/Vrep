// StandardSubsystems
//Hello!!!
// StandardSubsystems.BaseFunctionality
//  
// Flag that shows whether the file system installation must be suggested in the current session.
Var SuggestFileSystemExtensionInstallation Export;
// ApplicationParameters - Map - variable storage where:
//   * Key - String - variable name in the format as LibraryName.VariableName;
//   * Value - Arbitrary - variable value.
//  
// Initialization (based on EventLogMonitorMessages example):
//   ParameterName = "StandardSubsystems.EventLogMonitorMessages";
//   If ApplicationParameters[ParameterName] =
//     Undefined Then ApplicationParameters.Insert(ParameterName, New ValueList);
//   EndIf;
//  
// Usage (based on EventLogMonitorMessages example):
//   ApplicationParameters["StandardSubsystems.EventLogMonitorMessages"].Add(...);
//   ApplicationParameters["StandardSubsystems.EventLogMonitorMessages"] = ...;
Var ApplicationParameters Export;
// End StandardSubsystems

// StandardSubsystems.Peripherals
Var glPeripherals Export; // for caching on the client
Var glAvailableEquipmentTypes Export;
// End of StandardSubsystems.Peripherals

// ElectronicInteraction
Var ExchangeWithBanksSubsystemsParameters Export;
// For the relevant DS certificate settings the Certificate-Password pairs will be stored accordingly (in this session)
Var CertificateAndPasswordMatching Export;
// End of ElectronicInteraction

// ServiceTechnology
Var AlertOnRequestForExternalResourcesUseSaaS Export;
// End ServiceTechnology

#Region EventsHandlers

Procedure BeforeStart()
	
	// StandardSubsystems
	StandardSubsystemsClient.BeforeStart();
	// End StandardSubsystems
	
	// StandardSubsystems.PerformanceEstimation
	PerformanceEstimationClientServer.StartTimeMeasurement("ApplicationStart");
	// End StandardSubsystems.PerformanceEstimation
	
EndProcedure

Procedure OnStart()
	
	// StandardSubsystems
	StandardSubsystemsClient.OnStart();
	// End StandardSubsystems
	
	// StandardSubsystems.Peripherals
	EquipmentManagerClient.OnStart();
	// End of StandardSubsystems.Peripherals
	
	//SB
	SettingsModified = False;
	SmallBusinessServer.ConfigureUserDesktop(SettingsModified);
	If SettingsModified Then
		RefreshInterface();
	EndIf;
	//SB
	
EndProcedure

Procedure BeforeExit(Cancel, WarningText)
	
	// StandardSubsystems
	StandardSubsystemsClient.BeforeExit(Cancel, WarningText);
	// End StandardSubsystems
	
	// StandardSubsystems.Peripherals
	EquipmentManagerClient.BeforeExit();
	// End of StandardSubsystems.Peripherals

EndProcedure

// StandardSubsystems.Peripherals
Procedure ExternEventProcessing(Source, Event, Data)
	
	// Prepare data
	DetailsEvents = New Structure();
	ErrorDescription  = "";
	
	If UPPER(Event) = "ШТРИХКОД" Then
		Event = "Barcode";
	EndIf;
		
	DetailsEvents.Insert("Source", Source);
	DetailsEvents.Insert("Event",  Event);
	DetailsEvents.Insert("Data",   Data);

	// Transfer data for processing
	Result = EquipmentManagerClient.ProcessEventFromDevice(DetailsEvents, ErrorDescription);
	If Not Result Then
		CommonUseClientServer.MessageToUser(NStr("en='An error occurred when processing an external event from the device.';ru='При обработке внешнего события от устройства произошла ошибка.';vi='Khi xử lý sự kiện ngoài từ thiết bị xảy ra lỗi:'")
															+ Chars.LF + ErrorDescription);
	EndIf;
	
EndProcedure
// End of StandardSubsystems.Peripherals

#EndRegion