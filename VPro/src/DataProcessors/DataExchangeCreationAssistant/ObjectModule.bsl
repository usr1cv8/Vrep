#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Var ErrorMessageStringField; // String - variable contains string with error message.

#Region ServiceProceduresAndFunctions

////////////////////////////////////////////////////////////////////////////////
// Export service procedures and functions.

// Executes actions while creating a new data exchange:
// - creates or updates the current exchange plan nodes
// - imports conversion rules with data from the current exchange plan layout (if NOT DIB)
// - imports registration rules with data from the current exchange plan
// - imports exchange plan transport settings
// - sets the value of infobase prefix constant (if it is not specified)
// - registers all data on the current exchange plan node considering the objects registration rules.
//
// Parameters:
//  Cancel - Boolean - refusal flag which is set to True when there were errors during the execution of the procedure.
// 
Procedure ExecuteNewDataExchangeConfigureActions(Cancel,
	FilterSettingsAtNode,
	DefaultValuesAtNode,
	RecordDataForExport = True,
	UseTransportSettings = True) Export
	
	ThisNodeCode = GetThisBaseNodeCode(SourceInfobasePrefix);
	NewNodeCode = ?(AssistantOperationOption = "ContinueDataExchangeSetup", SecondInfobaseNewNodeCode, DataExchangeServer.ExchangePlanNodeCodeString(TargetInfobasePrefix));
	
	SetUpDataExchange(Cancel, FilterSettingsAtNode, DefaultValuesAtNode, ThisNodeCode, NewNodeCode, RecordDataForExport, UseTransportSettings);
	
EndProcedure

// Executes actions for setting a new exchange in Service.
//
Procedure SetupNewSaaSDataExchange(Cancel,
	FilterSettingsAtNode,
	DefaultValuesAtNode,
	Val ThisNodeCode,
	Val NewNodeCode) Export
	
	FilterSettingsAtNode    = GetFilterSettingsValues(FilterSettingsAtNode);
	DefaultValuesAtNode = GetFilterSettingsValues(DefaultValuesAtNode);
	
	SetUpDataExchange(Cancel, FilterSettingsAtNode, DefaultValuesAtNode, ThisNodeCode, NewNodeCode);
	
EndProcedure

// Executes actions for setting a new data exchange for both bases.
//
Procedure SetUpNewDataExchangeOverWebServiceInTwoBases(Cancel,
	FilterSettingsAtNode,
	LongOperation,
	DataExchangeCreationActionID) Export
	
	SetPrivilegedMode(True);
	
	DefaultValuesAtNode = New Structure;
	
	ErrorMessageStringField = Undefined;
	ExchangeMessageTransportKind = Enums.ExchangeMessagesTransportKinds.WS;
	UseTransportParametersCOM = False;
	
	ThisNodeCode = GetThisBaseNodeCode(SourceInfobasePrefix);
	NewNodeCode = GetCorrespondentNodeCode();
	
	ConnectionParameters = DataExchangeServer.WSParameterStructure();
	
	FillPropertyValues(ConnectionParameters, ThisObject);
	
	If CorrespondentVersion_2_1_1_7 Then
		
		WSProxy = DataExchangeServer.GetWSProxy_2_1_1_7(ConnectionParameters);
		
	ElsIf CorrespondentVersion_2_0_1_6 Then
		
		WSProxy = DataExchangeServer.GetWSProxy_2_0_1_6(ConnectionParameters);
		
	Else
		
		WSProxy = DataExchangeServer.GetWSProxy(ConnectionParameters);
		
	EndIf;
	
	If WSProxy = Undefined Then
		Cancel = True;
		Return;
	EndIf;
	
	BeginTransaction();
	Try
		
		// create a new node
		CreateRefreshExchangePlanNodes(FilterSettingsAtNode.FilterSettingsAtNode, DefaultValuesAtNode, ThisNodeCode, NewNodeCode);
		
		// Import the message transport settings.
		UpdateSettingsOfExchangeMessagesTransport();
		
		// Update IB prefix constant value.
		If Not SourceInfobasePrefixFilled Then
			
			RefreshIBPrefixConstantValue();
			
		EndIf;
		
		// Exports the assistant parameters to the string.
		AssistantParameterStringXML = RunAssistantParametersDump(Cancel);
		
		If Cancel Then
			Raise NStr("en='When creating exchange setting in the second infobase, errors occurred.';ru='При создании настройки обмена во второй информационной базе возникли ошибки.';vi='Khi tạo tùy chỉnh trao đổi trong cơ sở thông tin thứ hai có phát sinh lỗi.'");
		EndIf;
		
		// {Handler: OnSendingSenderData} Start
		ExchangePlans[ExchangePlanName].OnDataSendingSender(FilterSettingsAtNode, False);
		// {Handler: OnSendingSenderData} End
		
		If CorrespondentVersion_2_1_1_7 Then
			
			Serializer = New XDTOSerializer(WSProxy.XDTOFactory);
			
			WSProxy.CreateDataExchange(ExchangePlanName, 
							AssistantParameterStringXML, 
							Serializer.WriteXDTO(ShieldEnums(FilterSettingsAtNode.CorrespondentInfobaseNodeFilterSetup)),
							Serializer.WriteXDTO(ShieldEnums(DefaultValuesAtNode)));
			
		ElsIf CorrespondentVersion_2_0_1_6 Then
			
			Serializer = New XDTOSerializer(WSProxy.XDTOFactory);
			
			WSProxy.CreateDataExchange(ExchangePlanName,
							AssistantParameterStringXML,
							Serializer.WriteXDTO(FilterSettingsAtNode.CorrespondentInfobaseNodeFilterSetup),
							Serializer.WriteXDTO(DefaultValuesAtNode));
			
		Else
			
			WSProxy.CreateDataExchange(ExchangePlanName,
							AssistantParameterStringXML,
							ValueToStringInternal(FilterSettingsAtNode.CorrespondentInfobaseNodeFilterSetup),
							ValueToStringInternal(DefaultValuesAtNode));
			
		EndIf;
		
	Except
		
		MessageInformationAboutError(ErrorInfo(), Cancel);
		
	EndTry;
	
	If Cancel Then
		
		RollbackTransaction();
		
		Return;
		
	Else
		CommitTransaction();
	EndIf;
	
	// Register only changes in catalogs and CCT.
	Try
		DataExchangeServer.RegisterOnlyCatalogsForInitialLandings(InfobaseNode);
	Except
		MessageInformationAboutError(ErrorInfo(), Cancel);
		Return;
	EndTry;
	
	// Register changes in the second IB.
	WSProxy.RecordCatalogChangesOnly(
			ExchangePlanName,
			DataExchangeReUse.GetThisNodeCodeForExchangePlan(ExchangePlanName),
			LongOperation,
			DataExchangeCreationActionID);
	
EndProcedure

// Executes actions while creating a new data exchange via the external connection.
//
Procedure SetUpNewDataExchangeOverExternalConnection(Cancel,
	FilterSettingsAtNode,
	DefaultValuesAtNode,
	CorrespondentInfobaseNodeFilterSetup,
	CorrespondentInfobaseNodeDefaultValues) Export
	
	ErrorMessageStringField = Undefined;
	ExchangeMessageTransportKind = Enums.ExchangeMessagesTransportKinds.COM;
	UseTransportParametersCOM = True;
	
	ThisNodeCode = GetThisBaseNodeCode(SourceInfobasePrefix);
	NewNodeCode = DataExchangeServer.ExchangePlanNodeCodeString(TargetInfobasePrefix);
	
	// Creating outer join
	Connection = DataExchangeServer.InstallOuterDatabaseJoin(ThisObject);
	ErrorMessageStringField = Connection.DetailedErrorDescription;
	ExternalConnection           =   Connection.Join;
	
	If ExternalConnection = Undefined Then
		Cancel = True;
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	Try
		
		// create a new node
		CreateRefreshExchangePlanNodes(FilterSettingsAtNode, DefaultValuesAtNode, ThisNodeCode, NewNodeCode);
		
		// Import the message transport settings.
		UpdateCOMExchangeMessageTransportSettings();
		
		// Update IB prefix constant value.
		If Not SourceInfobasePrefixFilled Then
			
			RefreshIBPrefixConstantValue();
			
		EndIf;
		
		// Exports the assistant parameters to the string.
		AssistantParameterStringXML = RunAssistantParametersDump(Cancel);
		
		If Cancel Then
			Raise NStr("en='When creating exchange setting in the second infobase, errors occurred.';ru='При создании настройки обмена во второй информационной базе возникли ошибки.';vi='Khi tạo tùy chỉnh trao đổi trong cơ sở thông tin thứ hai có phát sinh lỗi.'");
		EndIf;
		
		// Get data processor of the exchange settings assistant on the second base.
		DataExchangeCreationAssistant = ExternalConnection.DataProcessors.DataExchangeCreationAssistant.Create();
		DataExchangeCreationAssistant.ExchangePlanName = ExchangePlanName;
		
		// Import assistant parameters from string to assistant data processor.
		DataExchangeCreationAssistant.ExternalConnectionImportAssistantParameters(Cancel, AssistantParameterStringXML);
		
		If Cancel Then
			Message = NStr("en='When creating exchange setting in the second infobase, errors occurred: %1';ru='При создании настройки обмена во второй информационной базе возникли ошибки: %1';vi='Khi tạo tùy chỉnh trao đổi trong cơ sở thông tin thứ hai phát sinh lỗi: %1'");
			Message = StringFunctionsClientServer.SubstituteParametersInString(Message, DataExchangeCreationAssistant.ErrorMessageString());
			Raise Message;
		EndIf;
		
		// Create exchange settings in the second IB via the external connection.
		If CorrespondentVersion_2_1_1_7 OR CorrespondentVersion_2_0_1_6 Then
			
			DataExchangeCreationAssistant.ExternalConnectionSetUpNewDataExchange_2_0_1_6(Cancel,
														CommonUse.ValueToXMLString(CorrespondentInfobaseNodeFilterSetup),
														CommonUse.ValueToXMLString(CorrespondentInfobaseNodeDefaultValues),
														TargetInfobasePrefixIsSet,
														TargetInfobasePrefix);
			
		Else
			
			DataExchangeCreationAssistant.ExternalConnectionSetUpNewDataExchange(Cancel,
														ValueToStringInternal(CorrespondentInfobaseNodeFilterSetup),
														ValueToStringInternal(CorrespondentInfobaseNodeDefaultValues),
														TargetInfobasePrefixIsSet,
														TargetInfobasePrefix);
			
		EndIf;
		
		If Cancel Then
			Message = NStr("en='When creating exchange setting in the second infobase, errors occurred: %1';ru='При создании настройки обмена во второй информационной базе возникли ошибки: %1';vi='Khi tạo tùy chỉnh trao đổi trong cơ sở thông tin thứ hai phát sinh lỗi: %1'");
			Message = StringFunctionsClientServer.SubstituteParametersInString(Message, DataExchangeCreationAssistant.ErrorMessageString());
			Raise Message;
		EndIf;
		
	Except
		
		MessageInformationAboutError(ErrorInfo(), Cancel);
		
	EndTry;
	
	If Cancel Then
		
		RollbackTransaction();
		
		Return;
		
	Else
		CommitTransaction();
	EndIf;
	
	// Register changes on the exchange plan node.
	RecordChangesForExchange(Cancel);
	
	// Register changes in the second IB via the external connection.
	DataExchangeCreationAssistant.ExternalConnectionRecordChangesForExchange();
	
EndProcedure

// Update the data exchange settings.
//
Procedure UpdateDataExchangeSettings(Cancel,
	DefaultValuesAtNode,
	CorrespondentInfobaseNodeDefaultValues,
	LongOperation,
	DataExchangeCreationActionID) Export
	
	SetPrivilegedMode(True);
	
	ErrorMessageStringField = Undefined;
	
	ConnectionParameters = DataExchangeServer.WSParameterStructure();
	
	FillPropertyValues(ConnectionParameters, ThisObject);
	
	If CorrespondentVersion_2_1_1_7 Then
		
		WSProxy = DataExchangeServer.GetWSProxy_2_1_1_7(ConnectionParameters);
		
	ElsIf CorrespondentVersion_2_0_1_6 Then
			
		WSProxy = DataExchangeServer.GetWSProxy_2_0_1_6(ConnectionParameters);
		
	Else
		
		WSProxy = DataExchangeServer.GetWSProxy(ConnectionParameters);
		
	EndIf;
	
	If WSProxy = Undefined Then
		Cancel = True;
		Return;
	EndIf;
	
	BeginTransaction();
	Try
		
		// Update settings for the node.
		InfobaseNodeObject = InfobaseNode.GetObject();
		
		// Set default values.
		DataExchangeEvents.SetDefaultValuesAtNode(InfobaseNodeObject, DefaultValuesAtNode);
		
		InfobaseNodeObject.AdditionalProperties.Insert("GettingExchangeMessage");
		InfobaseNodeObject.Write();
		
		If CorrespondentVersion_2_1_1_7 OR CorrespondentVersion_2_0_1_6 Then
			
			Serializer = New XDTOSerializer(WSProxy.XDTOFactory);
			
			WSProxy.UpdateDataExchangeSettings(
								ExchangePlanName,
								DataExchangeReUse.GetThisNodeCodeForExchangePlan(ExchangePlanName),
								Serializer.WriteXDTO(ShieldEnums(CorrespondentInfobaseNodeDefaultValues)));
		Else
			
			WSProxy.UpdateDataExchangeSettings(
								ExchangePlanName,
								DataExchangeReUse.GetThisNodeCodeForExchangePlan(ExchangePlanName),
								ValueToStringInternal(CorrespondentInfobaseNodeDefaultValues));
		EndIf;
		
	Except
		
		MessageInformationAboutError(ErrorInfo(), Cancel);
		
	EndTry;
	
	If Cancel Then
		
		RollbackTransaction();
		
		Return;
		
	Else
		CommitTransaction();
	EndIf;
	
	// Register changes of all data except for the catalogs and CCT.
	Try
		DataExchangeServer.RegisterAllDataExceptCatalogsForInitialExporting(InfobaseNode);
	Except
		MessageInformationAboutError(ErrorInfo(), Cancel);
		Return;
	EndTry;
	
	// Register changes in the second IB.
	WSProxy.RecordAllChangesExceptCatalogs(
			ExchangePlanName,
			DataExchangeReUse.GetThisNodeCodeForExchangePlan(ExchangePlanName),
			LongOperation,
			DataExchangeCreationActionID);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// For work via the external connection.

// Executes actions while creating a new data exchange via the external connection.
//
Procedure ExternalConnectionSetUpNewDataExchange(Cancel, 
									CorrespondentInfobaseNodeFilterSetup, 
									CorrespondentInfobaseNodeDefaultValues, 
									InfobasePrefixSet, 
									InfobasePrefix
	) Export
	
	DataExchangeServer.CheckUseDataExchange();
	
	FilterSettingsAtNode    = GetFilterSettingsValues(ValueFromStringInternal(CorrespondentInfobaseNodeFilterSetup));
	DefaultValuesAtNode = GetFilterSettingsValues(ValueFromStringInternal(CorrespondentInfobaseNodeDefaultValues));
	
	ErrorMessageStringField = Undefined;
	AssistantOperationOption = "ContinueDataExchangeSetup";
	
	ThisNodeCode = GetThisBaseNodeCode(SourceInfobasePrefix);
	NewNodeCode = SecondInfobaseNewNodeCode;
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	Try
		
		// create a new node
		CreateRefreshExchangePlanNodes(FilterSettingsAtNode, DefaultValuesAtNode, ThisNodeCode, NewNodeCode);
		
		// Import the message transport settings.
		UpdateCOMExchangeMessageTransportSettings();
		
		// Update IB prefix constant value.
		If Not InfobasePrefixSet Then
			
			ValueBeforeUpdate = GetFunctionalOption("InfobasePrefix");
			
			If ValueBeforeUpdate <> InfobasePrefix Then
				
				Constants.DistributedInformationBaseNodePrefix.Set(TrimAll(InfobasePrefix));
				
			EndIf;
			
		EndIf;
		
	Except
		
		MessageInformationAboutError(ErrorInfo(), Cancel);
		
	EndTry;
	
	If Cancel Then
		
		RollbackTransaction();
		
		Return;
		
	Else
		CommitTransaction();
	EndIf;
	
EndProcedure

// Executes actions while creating a new data exchange via the external connection.
//
Procedure ExternalConnectionSetUpNewDataExchange_2_0_1_6(Cancel, 
									CorrespondentInfobaseNodeFilterSetup, 
									CorrespondentInfobaseNodeDefaultValues, 
									InfobasePrefixSet, 
									InfobasePrefix
	) Export
	
	FilterSettingsAtNode    = GetFilterSettingsValues(CommonUse.ValueFromXMLString(CorrespondentInfobaseNodeFilterSetup));
	DefaultValuesAtNode = GetFilterSettingsValues(CommonUse.ValueFromXMLString(CorrespondentInfobaseNodeDefaultValues));
	
	ErrorMessageStringField = Undefined;
	AssistantOperationOption = "ContinueDataExchangeSetup";
	
	ThisNodeCode = GetThisBaseNodeCode(SourceInfobasePrefix);
	NewNodeCode = SecondInfobaseNewNodeCode;
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	Try
		
		DataExchangeServer.CheckUseDataExchange();
		
		// create a new node
		CreateRefreshExchangePlanNodes(FilterSettingsAtNode, DefaultValuesAtNode, ThisNodeCode, NewNodeCode);
		
		// Import the message transport settings.
		UpdateCOMExchangeMessageTransportSettings();
		
		// Update IB prefix constant value.
		If Not InfobasePrefixSet Then
			
			ValueBeforeUpdate = GetFunctionalOption("InfobasePrefix");
			
			If ValueBeforeUpdate <> InfobasePrefix Then
				
				Constants.DistributedInformationBaseNodePrefix.Set(TrimAll(InfobasePrefix));
				
			EndIf;
			
		EndIf;
		
	Except
		
		MessageInformationAboutError(ErrorInfo(), Cancel);
		
	EndTry;
	
	If Cancel Then
		
		RollbackTransaction();
		
		Return;
		
	Else
		CommitTransaction();
	EndIf;
	
EndProcedure

// Registers changes on the exchange plan node.
//
Procedure ExternalConnectionRecordChangesForExchange() Export
	
	// Register changes on the exchange plan node.
	RecordChangesForExchange(False);
	
EndProcedure

// Reads exchange assistant settings from XML string.
//
Procedure ExternalConnectionImportAssistantParameters(Cancel, XMLString) Export
	
	RunAssistantParametersImport(Cancel, XMLString);
	
EndProcedure

// Updates the data exchange node settings via the external connection, sets default values.
//
Procedure ExternalConnectionRefreshExchangeSettingsData(DefaultValuesAtNode) Export
	
	BeginTransaction();
	Try
		
		// Update settings for the node.
		InfobaseNodeObject = InfobaseNode.GetObject();
		
		// Set default values.
		DataExchangeEvents.SetDefaultValuesAtNode(InfobaseNodeObject, DefaultValuesAtNode);
		
		InfobaseNodeObject.AdditionalProperties.Insert("GettingExchangeMessage");
		InfobaseNodeObject.Write();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

//

// Executes actions while creating a new data exchange via the web service.
// For a detailed description, see the ExecuteNewDataExchangeSettingActions procedure.
//
Procedure SetUpNewWebSaaSDataExchange(Cancel, FilterSettingsAtNode, DefaultValuesAtNode) Export
	
	FilterSettingsAtNode    = GetFilterSettingsValues(FilterSettingsAtNode);
	DefaultValuesAtNode = GetFilterSettingsValues(DefaultValuesAtNode);
	
	// {Handler: AtReceivingSenderData} Begin
	Try
		ExchangePlans[ExchangePlanName].OnSendersDataGet(FilterSettingsAtNode, False);
	Except
		MessageInformationAboutError(ErrorInfo(), Cancel);
		Return;
	EndTry;
	// {Handler: AtReceivingSenderData} End
	
	ExecuteNewDataExchangeConfigureActions(Cancel,
													FilterSettingsAtNode,
													DefaultValuesAtNode,
													False,
													False);
	
EndProcedure

// Imports assistant parameters to the temporary storage to continue exchange setting in the second base.
//
// Parameters:
//  Cancel - Boolean - refusal flag which is set to True when there were errors during the execution of the procedure.
//  TemporaryStorageAddress - String - if the xml-file with settings
//                                      is exported successfully, address of the temporary
//                                      storage according to which the file data will be available on server or client is written to this variable.
// 
Procedure RunAssistantParametersDumpIntoTemporaryStorage(Cancel, TemporaryStorageAddress) Export
	
	SetPrivilegedMode(True);
	
	// Get temporary attachment file name in the local FS on server.
	TempFileName = GetTempFileName("xml");
	
	Try
		TextWriter = New TextWriter(TempFileName, TextEncoding.UTF8);
	Except
		DataExchangeServer.ShowMessageAboutError(BriefErrorDescription(ErrorInfo()), Cancel);
		Return;
	EndTry;
	
	XMLString = RunAssistantParametersDump(Cancel);
	
	If Not Cancel Then
		
		TextWriter.Write(XMLString);
		
	EndIf;
	
	TextWriter.Close();
	TextWriter = Undefined;
	
	TemporaryStorageAddress = PutToTempStorage(New BinaryData(TempFileName));
	
	DeleteTemporaryFile(TempFileName);
	
EndProcedure

// Imports assistant parameters to the constant to continue exchange setting in subordinate DIB node.
//
// Parameters:
//  Cancel - Boolean - refusal flag which is set to True when there were errors during the execution of the procedure.
// 
Procedure RunAssistantParametersDumpIntoConstant(Cancel) Export
	
	SetPrivilegedMode(True);
	
	XMLString = RunAssistantParametersDump(Cancel);
	
	If Not Cancel Then
		
		Constants.SubordinatedDIBNodeSetup.Set(XMLString);
		
		ExchangePlans.RecordChanges(InfobaseNode, Metadata.Constants.SubordinatedDIBNodeSetup);
		
	EndIf;
	
EndProcedure

// Imports assistant parameters from the temporary storage to continue exchange setting in the second base.
//
// Parameters:
//  Cancel - Boolean - refusal flag which is set to True when there were errors during the execution of the procedure.
//  TemporaryStorageAddress - String - address of the temporary storage with xml-file data for import
//
Procedure RunAssistantParametersImportFromTemporaryStorage(Cancel, TemporaryStorageAddress) Export
	
	SetPrivilegedMode(True);
	
	BinaryData = GetFromTempStorage(TemporaryStorageAddress);
	
	// Get temporary attachment file name in the local FS on server.
	TempFileName = GetTempFileName("xml");
	
	// Receive file for reading.
	BinaryData.Write(TempFileName);
	
	TextReader = New TextReader(TempFileName, TextEncoding.UTF8);
	
	XMLString = TextReader.Read();
	TextReader.Close();
	
	// delete a temporary file
	DeleteTemporaryFile(TempFileName);
	
	RunAssistantParametersImport(Cancel, XMLString);
	
EndProcedure

// Imports assistant parameters from the constant to continue exchange setting in the second base.
//
// Parameters:
//  Cancel - Boolean - refusal flag which is set to True when there were errors during the execution of the procedure.
//
Procedure RunAssistantParametersImportFromConstant(Cancel) Export
	
	SetPrivilegedMode(True);
	
	XMLString = Constants.SubordinatedDIBNodeSetup.Get();
	
	RunAssistantParametersImport(Cancel, XMLString);
	
EndProcedure

// Initializes exchange node settings.
//
Procedure Initialization(Node) Export
	
	InfobaseNode = Node;
	InfobaseNodeParameters = CommonUse.ObjectAttributesValues(Node, "Code, description");
	
	ExchangePlanName = DataExchangeReUse.GetExchangePlanName(InfobaseNode);
	
	ThisInfobaseDescription = CommonUse.ObjectAttributeValue(ExchangePlans[ExchangePlanName].ThisNode(), "Description");
	SecondInfobaseDescription = InfobaseNodeParameters.Description;
	
	TargetInfobasePrefix = InfobaseNodeParameters.Code;
	
	TransportSettings = InformationRegisters.ExchangeTransportSettings.TransportSettings(Node);
	
	FillPropertyValues(ThisObject, TransportSettings);
	
	ExchangeMessageTransportKind = TransportSettings.ExchangeMessageTransportKindByDefault;
	
	UseTransportParametersCOM = False;
	UseTransportParametersEMAIL = False;
	UseTransportParametersFILE = False;
	UseTransportParametersFTP = False;
	
	If ExchangeMessageTransportKind = Enums.ExchangeMessagesTransportKinds.FILE Then
		
		UseTransportParametersFILE = True;
		
	ElsIf ExchangeMessageTransportKind = Enums.ExchangeMessagesTransportKinds.FTP Then
		
		UseTransportParametersFTP = True;
		
	ElsIf ExchangeMessageTransportKind = Enums.ExchangeMessagesTransportKinds.EMAIL Then
		
		UseTransportParametersEMAIL = True;
		
	ElsIf ExchangeMessageTransportKind = Enums.ExchangeMessagesTransportKinds.COM Then
		
		UseTransportParametersCOM = True;
		
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Functions-properties

// Error message during the data exchange.
//
// Returns:
//  String - Error message during the data exchange.
//
Function ErrorMessageString() Export
	
	If TypeOf(ErrorMessageStringField) <> Type("String") Then
		
		ErrorMessageStringField = "";
		
	EndIf;
	
	Return ErrorMessageStringField;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Helper service procedures and functions.

Procedure SetUpDataExchange(
		Cancel, 
		FilterSettingsAtNode, 
		DefaultValuesAtNode, 
		ThisNodeCode, 
		NewNodeCode, 
		RecordDataForExport = True, 
		UseTransportSettings = True)
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	Try
		
		// Create/update exchange plan nodes.
		CreateRefreshExchangePlanNodes(FilterSettingsAtNode, DefaultValuesAtNode, ThisNodeCode, NewNodeCode);
		
		If UseTransportSettings Then
			
			// Import the message transport settings.
			UpdateSettingsOfExchangeMessagesTransport();
			
		EndIf;
		
		// Update IB prefix constant value.
		If Not SourceInfobasePrefixFilled Then
			
			RefreshIBPrefixConstantValue();
			
		EndIf;
		
		If ThisIsSettingOfDistributedInformationBase
			AND AssistantOperationOption = "ContinueDataExchangeSetup" Then
			
			// Exchange plans do not migrate to DIB, therefore import rules.
			DataExchangeServer.ExecuteUpdateOfDataExchangeRules();
			
			Constants.SubordinatedDIBNodeSettingsFinished.Set(True);
			Constants.UseDataSynchronization.Set(True);
			Constants.DontUseSeparationByDataAreas.Set(True);
			
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		MessageInformationAboutError(ErrorInfo(), Cancel);
		Return;
	EndTry;
	
	// Update ORM reused values.
	DataExchangeServerCall.CheckObjectRegistrationMechanismCache();
	
	If RecordDataForExport
		AND Not ThisIsSettingOfDistributedInformationBase Then
		
		// Register changes on the exchange plan node.
		RecordChangesForExchange(Cancel);
		
	EndIf;
	
EndProcedure

Procedure CreateRefreshExchangePlanNodes(FilterSettingsAtNode, DefaultValuesAtNode, ThisNodeCode, NewNodeCode)
	
	// Check the content of exchange plan.
	StandardSubsystemsServer.ValidateExchangePlanContent(ExchangePlanName);
	
	ExchangePlanManager = ExchangePlans[ExchangePlanName];
	
	// UPDATE THIS NODE IF NEEDED
	
	// Receive reference to this exchange plan node.
	ThisNode = ExchangePlanManager.ThisNode();
	ThisNodeCodeInDB = CommonUse.ObjectAttributeValue(ThisNode, "Code");
	If IsBlankString(ThisNodeCodeInDB) Then
		
		ThisNodeObject = ThisNode.GetObject();
		ThisNodeObject.Code = ThisNodeCode;
		ThisNodeObject.Description = ThisInfobaseDescription;
		ThisNodeObject.AdditionalProperties.Insert("GettingExchangeMessage");
		ThisNodeObject.Write();
		
	EndIf;
	
	// RECEIVE NODE FOR EXCHANGE
	CreatingNewNode = False;
	If ThisIsSettingOfDistributedInformationBase
		AND AssistantOperationOption = "ContinueDataExchangeSetup" Then
		
		MasterNode = DataExchangeServer.MasterNode();
		
		If MasterNode = Undefined Then
			
			Raise NStr("en='The main node for the current infobase is not determined."
"Perhaps, the infobase is not a subordinate node in the RIB.';ru='Главный узел для текущей информационной базы не определен."
"Возможно, информационная база не является подчиненным узлом в РИБ.';vi='Nút chính đối với cơ sở thông tin này chưa xác định."
"Có thể, cơ sở thông tin không phải là nút trực thuộc trong CSTT phân tán.'");
		EndIf;
		
		NewNode = MasterNode.GetObject();
		
	Else
		
		// CREATE/UPDATE NODE
		NewNode = ExchangePlanManager.FindByCode(NewNodeCode);
		CreatingNewNode = NewNode.IsEmpty();
		If CreatingNewNode Then
			NewNode = ExchangePlanManager.CreateNode();
			NewNode.Code = NewNodeCode;
		Else
			NewNode = NewNode.GetObject();
		EndIf;
		
		NewNode.Description = SecondInfobaseDescription;
		
		If CommonUse.IsObjectAttribute("SettingVariant", Metadata.ExchangePlans[ExchangePlanName]) Then
			NewNode.SettingVariant = ExchangeSettingsVariant;
		EndIf;
		
	EndIf;
	
	// Set filter values on a new node.
	DataExchangeEvents.SetValuesOfFiltersAtNode(NewNode, FilterSettingsAtNode);
	
	// Set the default values on a new node.
	DataExchangeEvents.SetDefaultValuesAtNode(NewNode, DefaultValuesAtNode);
	
	// Reset messages counters.
	NewNode.SentNo = 0;
	NewNode.ReceivedNo     = 0;
	
	If CommonUseReUse.DataSeparationEnabled()
		AND CommonUseReUse.CanUseSeparatedData()
		AND DataExchangeServer.IsSeparatedExchangePlanSSL(ExchangePlanName) Then
		
		NewNode.RegisterChanges = True;
		
	EndIf;
	
	If ValueIsFilled(RefNew) Then
		NewNode.SetNewObjectRef(RefNew);
	EndIf;
	
	NewNode.DataExchange.Load = True;
	NewNode.Write();
	
	InfobaseNode = NewNode.Ref;
	
	If CreatingNewNode
		And Not CommonUseReUse.DataSeparationEnabled() Then
		DataExchangeServer.ExecuteUpdateOfDataExchangeRules();
	EndIf;
	
EndProcedure

Procedure UpdateSettingsOfExchangeMessagesTransport()
	
	RecordStructure = New Structure;
	RecordStructure.Insert("Node",                                    InfobaseNode);
	RecordStructure.Insert("ExchangeMessageTransportKindByDefault", ExchangeMessageTransportKind);
	
	RecordStructure.Insert("WSUseLargeDataTransfer", True);
	
	SupplementStructureWithAttributeValue(RecordStructure, "EMAILMaximumValidMessageSize");
	SupplementStructureWithAttributeValue(RecordStructure, "EMAILCompressOutgoingMessageFile");
	SupplementStructureWithAttributeValue(RecordStructure, "EMAILAccount");
	SupplementStructureWithAttributeValue(RecordStructure, "FILEInformationExchangeDirectory");
	SupplementStructureWithAttributeValue(RecordStructure, "FILECompressOutgoingMessageFile");
	SupplementStructureWithAttributeValue(RecordStructure, "FTPCompressOutgoingMessageFile");
	SupplementStructureWithAttributeValue(RecordStructure, "FTPConnectionMaximumValidMessageSize");
	SupplementStructureWithAttributeValue(RecordStructure, "FTPConnectionPassword");
	SupplementStructureWithAttributeValue(RecordStructure, "FTPConnectionPassiveConnection");
	SupplementStructureWithAttributeValue(RecordStructure, "FTPConnectionUser");
	SupplementStructureWithAttributeValue(RecordStructure, "FTPConnectionPort");
	SupplementStructureWithAttributeValue(RecordStructure, "FTPConnectionPath");
	SupplementStructureWithAttributeValue(RecordStructure, "WSURLWebService");
	SupplementStructureWithAttributeValue(RecordStructure, "WSUserName");
	SupplementStructureWithAttributeValue(RecordStructure, "WSPassword");
	SupplementStructureWithAttributeValue(RecordStructure, "WSRememberPassword");
	SupplementStructureWithAttributeValue(RecordStructure, "ExchangeMessageArchivePassword");
	
	// add record to the information register
	InformationRegisters.ExchangeTransportSettings.AddRecord(RecordStructure);
	
EndProcedure

Procedure UpdateCOMExchangeMessageTransportSettings()
	
	RecordStructure = New Structure;
	RecordStructure.Insert("Node",                                    InfobaseNode);
	RecordStructure.Insert("ExchangeMessageTransportKindByDefault", Enums.ExchangeMessagesTransportKinds.COM);
	
	SupplementStructureWithAttributeValue(RecordStructure, "COMAuthenticationOS");
	SupplementStructureWithAttributeValue(RecordStructure, "COMInfobaseOperationMode");
	SupplementStructureWithAttributeValue(RecordStructure, "COMInfobaseNameAtServer1CEnterprise");
	SupplementStructureWithAttributeValue(RecordStructure, "COMUserName");
	SupplementStructureWithAttributeValue(RecordStructure, "COMServerName1CEnterprise");
	SupplementStructureWithAttributeValue(RecordStructure, "COMInfobaseDirectory");
	SupplementStructureWithAttributeValue(RecordStructure, "COMUserPassword");
	
	// add record to the information register
	InformationRegisters.ExchangeTransportSettings.AddRecord(RecordStructure);
	
EndProcedure

Procedure SupplementStructureWithAttributeValue(RecordStructure, AttributeName)
	
	RecordStructure.Insert(AttributeName, ThisObject[AttributeName]);
	
EndProcedure

Procedure RefreshIBPrefixConstantValue()
	
	ValueBeforeUpdate = GetFunctionalOption("InfobasePrefix");
	
	If IsBlankString(ValueBeforeUpdate)
		AND ValueBeforeUpdate <> SourceInfobasePrefix Then
		
		Constants.DistributedInformationBaseNodePrefix.Set(TrimAll(SourceInfobasePrefix));
		
	EndIf;
	
EndProcedure

Procedure RecordChangesForExchange(Cancel)
	
	Try
		DataExchangeServer.RegisterDataForInitialExport(InfobaseNode);
	Except
		MessageInformationAboutError(ErrorInfo(), Cancel);
		Return;
	EndTry;
	
EndProcedure

Function RunAssistantParametersDump(Cancel)
	
	Try
		
		XMLWriter = New XMLWriter;
		XMLWriter.SetString("UTF-8");
		XMLWriter.WriteXMLDeclaration();
		
		XMLWriter.WriteStartElement("SettingParameters");
		XMLWriter.WriteAttribute(DataEcxhangeParameterDescription("FormatVersion"), ExchangeDataSettingsFileFormatVersion());
		
		XMLWriter.WriteNamespaceMapping("xsd", "http://www.w3.org/2001/XMLSchema");
		XMLWriter.WriteNamespaceMapping("xsi", "http://www.w3.org/2001/XMLSchema-instance");
		XMLWriter.WriteNamespaceMapping("v8", "http://v8.1c.ru/data");
		
		// Export the assistant parameters.
		XMLWriter.WriteStartElement("MainExchangeParameters");
		DumpAssistantParameters(XMLWriter);
		XMLWriter.WriteEndElement(); // MainExchangeParameters
		
		If UseTransportParametersEMAIL Then
			
			XMLWriter.WriteStartElement("EmailAccount");
			WriteXML(XMLWriter, ?(ValueIsFilled(EMAILAccount), EMAILAccount.GetObject(), Undefined));
			XMLWriter.WriteEndElement(); // EmailAccount
			
		EndIf;
		
		XMLWriter.WriteEndElement(); // SettingParameters
		
	Except
		DataExchangeServer.ShowMessageAboutError(BriefErrorDescription(ErrorInfo()), Cancel);
		Return "";
	EndTry;
	
	Return XMLWriter.Close();
	
EndFunction

Function GetThisBaseNodeCode(Val InfobasePrefixSpecifiedByUser)
	
	If AssistantOperationOption = "ContinueDataExchangeSetup"
		AND ExchangeDataSettingsFileFormatVersion = "1.0" Then
		
		Return PredefinedNodeCode;
		
	EndIf;
	
	Result = GetFunctionalOption("InfobasePrefix");
	
	If IsBlankString(Result) Then
		
		Result = InfobasePrefixSpecifiedByUser;
		
		If IsBlankString(Result) Then
			
			Return "000";
			
		EndIf;
		
	EndIf;
	
	Return DataExchangeServer.ExchangePlanNodeCodeString(Result);
EndFunction

Function GetCorrespondentNodeCode()
	
	If Not IsBlankString(CorrespondentNodeCode) Then
		
		Return CorrespondentNodeCode;
		
	EndIf;
	
	Return DataExchangeServer.ExchangePlanNodeCodeString(TargetInfobasePrefix);
EndFunction

Procedure ReadParametersToStructure(Cancel, XMLString, SettingsStructure)
	
	Try
		XMLReader = New XMLReader;
		XMLReader.SetString(XMLString);
	Except
		Cancel = True;
		XMLReader = Undefined;
		Return;
	EndTry;
	
	Try
		
		XMLReader.Read(); // SettingParameters
		FormatVersion = XMLReader.GetAttribute("FormatVersion");
		ExchangeDataSettingsFileFormatVersion = ?(FormatVersion = Undefined, "1.0", FormatVersion);
		
		XMLReader.Read(); // MainExchangeParameters
		
		// Read the MainExchangeParameters node.
		SettingsStructure = CalculateDataToStructure(XMLReader);
		
		If SettingsStructure.Property("UseTransportParametersEMAIL", UseTransportParametersEMAIL)
			AND UseTransportParametersEMAIL Then
			
			// Read the EmailAccount node.
			XMLReader.Read(); // EmailAccount {ItemStart}
			
			SettingsStructure.Insert("EmailAccount", ReadXML(XMLReader));
			
			XMLReader.Read(); // EmailAccount {ItemEnd}
			
		EndIf;
		
	Except
		Cancel = True;
	EndTry;
	
	XMLReader.Close();
	XMLReader = Undefined;
	
EndProcedure

// Reads exchange assistant settings from XML string.
//
Procedure RunAssistantParametersImport(Cancel, XMLString) Export
	
	Var SettingsStructure;
	
	ReadParametersToStructure(Cancel, XMLString, SettingsStructure);
	
	If SettingsStructure = Undefined Then
		Return;
	EndIf;
	
	// Check for the read parameters from file.
	If SettingsStructure.Property("ExchangePlanName")
		AND SettingsStructure.ExchangePlanName <> ExchangePlanName Then
		
		ErrorMessageStringField = NStr("en='The file contains exchange settings for a different infobase.';ru='Файл содержит настройки обмена для другой информационной базы.';vi='Tệp có tùy chỉnh trao đổi đối với cơ sở thông tin khác.'");
		DataExchangeServer.ShowMessageAboutError(ErrorMessageString(), Cancel);
		
	EndIf;
	
	If Not Cancel Then
		
		// Fill in the data processor properties with values from file.
		FillPropertyValues(ThisObject, SettingsStructure);
		
		FillPropertyFormAcc(SettingsStructure);
		
		EmailAccount = Undefined;
		
		If SettingsStructure.Property("EmailAccount", EmailAccount)
			AND EmailAccount <> Undefined Then
			
			EmailAccount.Write();
			
		EndIf;
		
		// Support the format exchange settings file of the version 1.0.
		If ExchangeDataSettingsFileFormatVersion = "1.0" Then
			
			ThisObject.ThisInfobaseDescription = NStr("en='This is an infobase';ru='Эта информационная база';vi='Cơ sở thông tin này'");
			ThisObject.SecondInfobaseDescription = ?(SettingsStructure.Property("ExchangeProcessingSettingName") = False,
				SettingsStructure.НаименованиеНастройкиВыполненияОбмена, SettingsStructure.ExchangeProcessingSettingName);
				
			ThisObject.SecondInfobaseNewNodeCode = ?(SettingsStructure.Property("NewNodeCode") = False, SettingsStructure.КодНовогоУзла, SettingsStructure.NewNodeCode);
			
		EndIf;
		
	EndIf;
	
	InfobasePrefix = GetFunctionalOption("InfobasePrefix");
	
	If Not IsBlankString(InfobasePrefix)
		AND InfobasePrefix <> SourceInfobasePrefix Then
		
		ErrorMessageStringField = NStr("en='Prefix of the second infobase was specified incorrectly at the first stage of the exchange setting."
"Exchange setup is required to be restarted.';ru='На первом этапе настройки обмена был неправильно указан префикс второй информационной базы."
"Настройку обмена требуется начать заново.';vi='Ở giai đoạn đầu tiên tùy chỉnh trao đổi đã chỉ ra sai tiền tố cơ sở thông tin thứ ha. Cần bắt đầu lại tùy chỉnh trao đổi.'");
		//
		DataExchangeServer.ShowMessageAboutError(ErrorMessageString(), Cancel);
		
	EndIf;
	
EndProcedure

Procedure  FillPropertyFormAcc(AccSettingsStructure)
	
	SetPropertyFromSetting(AccSettingsStructure, "FILEКаталогОбменаИнформацией", "FILEInformationExchangeDirectory");
	SetPropertyFromSetting(AccSettingsStructure, "FILEСжиматьФайлИсходящегоСообщения", "FILECompressOutgoingMessageFile");
	SetPropertyFromSetting(AccSettingsStructure, "ВидТранспортаСообщенийОбмена", "ExchangeMessageTransportKind");
	SetPropertyFromSetting(AccSettingsStructure, "ИмяПланаОбмена", "ExchangePlanName");
	SetPropertyFromSetting(AccSettingsStructure, "ИспользоватьПараметрыТранспортаEMAIL", "UseTransportParametersEMAIL");
	SetPropertyFromSetting(AccSettingsStructure, "ИспользоватьПараметрыТранспортаFILE", "UseTransportParametersFILE");
	SetPropertyFromSetting(AccSettingsStructure, "ИспользоватьПараметрыТранспортаFTP", "UseTransportParametersFTP");
	SetPropertyFromSetting(AccSettingsStructure, "КодНовогоУзлаВторойБазы", "SecondInfobaseNewNodeCode");
	SetPropertyFromSetting(AccSettingsStructure, "КодПредопределенногоУзла", "PredefinedNodeCode");
	SetPropertyFromSetting(AccSettingsStructure, "НаименованиеВторойБазы", "SecondInfobaseDescription");
	SetPropertyFromSetting(AccSettingsStructure, "НаименованиеЭтойБазы", "ThisInfobaseDescription");
	SetPropertyFromSetting(AccSettingsStructure, "ПарольАрхиваСообщенияОбмена", "ExchangeMessageArchivePassword");
	SetPropertyFromSetting(AccSettingsStructure, "ПрефиксИнформационнойБазыИсточника", "SourceInfobasePrefix");
	
EndProcedure

Procedure SetPropertyFromSetting(AccSettingsStructure, SettingPropName, ThisObjectPropName)
	
	If AccSettingsStructure.Property(SettingPropName) Then
		ThisObject[ThisObjectPropName] = AccSettingsStructure[SettingPropName];
	EndIf;
	
EndProcedure

Function CalculateDataToStructure(XMLReader)
	
	// Return value of the function.
	Structure = New Structure;
	
	If XMLReader.NodeType <> XMLNodeType.StartElement Then
		
		Raise NStr("en='XML reading error';ru='Ошибка чтения XML';vi='Lỗi đọc XML'");
		
	EndIf;
	
	XMLReader.Read();
	
	While XMLReader.NodeType <> XMLNodeType.EndElement Do
		
		NodeName = XMLReader.Name;
		
		Structure.Insert(NodeName, ReadXML(XMLReader));
		
	EndDo;
	
	XMLReader.Read();
	
	Return Structure;
	
EndFunction

Procedure DumpAssistantParameters(XMLWriter)
	
	AddXMLWriter(XMLWriter, "ExchangePlanName");
	
	WriteXML(XMLWriter, ThisInfobaseDescription, DataEcxhangeParameterDescription("SecondInfobaseDescription"), XMLTypeAssignment.Explicit);
	WriteXML(XMLWriter, SecondInfobaseDescription, DataEcxhangeParameterDescription("ThisInfobaseDescription"), XMLTypeAssignment.Explicit);
	
	WriteXML(XMLWriter, CommonUse.ObjectAttributeValue(ExchangePlans[ExchangePlanName].ThisNode(), "Code"), DataEcxhangeParameterDescription("SecondInfobaseNewNodeCode"), XMLTypeAssignment.Explicit);
	
	WriteXML(XMLWriter, TargetInfobasePrefix, DataEcxhangeParameterDescription("SourceInfobasePrefix"), XMLTypeAssignment.Explicit);
	
	// Exchange messages transport settings.
	If Upper(ExchangePlanName) = Upper("ExchangeCompanyManagementAccounting") Then
		AddXMLWriterExeption(XMLWriter, "ExchangeMessageTransportKind");
	Else
		AddXMLWriter(XMLWriter, "ExchangeMessageTransportKind");
	EndIf;
	
	AddXMLWriter(XMLWriter, "ExchangeMessageArchivePassword");
	
	If UseTransportParametersEMAIL Then
		
		AddXMLWriter(XMLWriter, "EMAILMaximumValidMessageSize");
		AddXMLWriter(XMLWriter, "EMAILCompressOutgoingMessageFile");
		AddXMLWriter(XMLWriter, "EMAILAccount");
		
	EndIf;
	
	If UseTransportParametersFILE Then
		
		AddXMLWriter(XMLWriter, "FILEInformationExchangeDirectory");
		AddXMLWriter(XMLWriter, "FILECompressOutgoingMessageFile");
		
	EndIf;
	
	If UseTransportParametersFTP Then
		
		AddXMLWriter(XMLWriter, "FTPCompressOutgoingMessageFile");
		AddXMLWriter(XMLWriter, "FTPConnectionMaximumValidMessageSize");
		AddXMLWriter(XMLWriter, "FTPConnectionPassword");
		AddXMLWriter(XMLWriter, "FTPConnectionPassiveConnection");
		AddXMLWriter(XMLWriter, "FTPConnectionUser");
		AddXMLWriter(XMLWriter, "FTPConnectionPort");
		AddXMLWriter(XMLWriter, "FTPConnectionPath");
		
	EndIf;
	
	If UseTransportParametersCOM Then
		
		ConnectionParameters = CommonUseClientServer.GetConnectionParametersFromInfobaseConnectionString(InfobaseConnectionString());
		
		InfobaseOperationMode             = ConnectionParameters.InfobaseOperationMode;
		InfobaseNameAtPlatformServer = ConnectionParameters.InfobaseNameAtPlatformServer;
		PlatformServerName                     = ConnectionParameters.PlatformServerName;
		InfobaseDirectory                   = ConnectionParameters.InfobaseDirectory;
		
		IBUser = InfobaseUsers.CurrentUser();
		OSAuthentication = IBUser.OSAuthentication;
		UserName                   = IBUser.Name;
		
		WriteXML(XMLWriter, InfobaseOperationMode,          DataEcxhangeParameterDescription("COMInfobaseOperationMode"),             XMLTypeAssignment.Explicit);
		WriteXML(XMLWriter, InfobaseNameAtPlatformServer, DataEcxhangeParameterDescription("COMInfobaseNameAtServer1CEnterprise"), XMLTypeAssignment.Explicit);
		WriteXML(XMLWriter, PlatformServerName,               DataEcxhangeParameterDescription("COMServerName1CEnterprise"),                     XMLTypeAssignment.Explicit);
		WriteXML(XMLWriter, InfobaseDirectory,                  DataEcxhangeParameterDescription("COMInfobaseDirectory"),                   XMLTypeAssignment.Explicit);
		WriteXML(XMLWriter, OSAuthentication,                  DataEcxhangeParameterDescription("COMAuthenticationOS"),           XMLTypeAssignment.Explicit);
		WriteXML(XMLWriter, UserName,                            DataEcxhangeParameterDescription( "COMUserName"),                             XMLTypeAssignment.Explicit);
		
	EndIf;
	
	AddXMLWriter(XMLWriter, "UseTransportParametersEMAIL");
	AddXMLWriter(XMLWriter, "UseTransportParametersFILE");
	AddXMLWriter(XMLWriter, "UseTransportParametersFTP");
	
	// Support the format exchange settings file of the version 1.0.
	WriteXML(XMLWriter, ThisInfobaseDescription, DataEcxhangeParameterDescription("ExchangeProcessingSettingName"), XMLTypeAssignment.Explicit);
	WriteXML(XMLWriter, CommonUse.ObjectAttributeValue(ExchangePlans[ExchangePlanName].ThisNode(), "Code"), DataEcxhangeParameterDescription("NewNodeCode"), XMLTypeAssignment.Explicit);
	WriteXML(XMLWriter, CommonUse.ObjectAttributeValue(InfobaseNode, "Code"), DataEcxhangeParameterDescription("PredefinedNodeCode"), XMLTypeAssignment.Explicit);
	
EndProcedure

Function DataEcxhangeParameterDescription(ParameterID)
	
	ExchangePlanMap = ExchangePlanDescription();
	ParametersDescription = ExchangePlanMap.Get(ExchangePlanName);
	
	If ParametersDescription = Undefined Then
		ParameterDescription = ParameterID;
	Else
		ParameterDescription = ParametersDescription.Get(ParameterID);
	EndIf;
	
	Return ParameterDescription;
	
EndFunction

Function ExchangePlanDescription()
	
	Result = New Map;
	Result.Insert("ExchangeCompanyManagementAccounting", ParametersDescription());
//	Result.Insert("ExchangeCompanyManagementAccounting40", ParametersDescription());
	
	Return Result;
	
EndFunction

Function ParametersDescription()
	
	Descriptions = New Map;
	
	Descriptions.Insert("FormatVersion", "ВерсияФормата");
	
	If Upper(ExchangeSettingsVariant) = Upper("Accounting3") Then
		Descriptions.Insert("ExchangePlanName", ReceiverProp("ИмяПланаОбмена", "ОбменУправлениеНебольшойФирмойБухгалтерия30"));
	Else
		Descriptions.Insert("ExchangePlanName", ReceiverProp("ИмяПланаОбмена", "ОбменУправлениеНебольшойФирмойБухгалтерия"));
	EndIf;
	
	Descriptions.Insert("SecondInfobaseDescription",		"НаименованиеВторойБазы");
	Descriptions.Insert("ThisInfobaseDescription",			"НаименованиеЭтойБазы");
	Descriptions.Insert("SecondInfobaseNewNodeCode",	"КодНовогоУзлаВторойБазы");
	Descriptions.Insert("SourceInfobasePrefix",				"ПрефиксИнформационнойБазыИсточника");
	
	Descriptions.Insert("ExchangeMessageTransportKind",		"ВидТранспортаСообщенийОбмена");
	Descriptions.Insert("ExchangeMessageArchivePassword",	"ПарольАрхиваСообщенияОбмена");
	
	Descriptions.Insert("EMAILMaximumValidMessageSize",			"EMAILМаксимальныйДопустимыйРазмерСообщения");
	Descriptions.Insert("EMAILCompressOutgoingMessageFile",	"EMAILСжиматьФайлИсходящегоСообщения");
	Descriptions.Insert("EMAILAccount",								"EMAILУчетнаяЗапись");
	
	Descriptions.Insert("FILEInformationExchangeDirectory",		"FILEКаталогОбменаИнформацией");
	Descriptions.Insert("FILECompressOutgoingMessageFile",		"FILEСжиматьФайлИсходящегоСообщения");
	
	Descriptions.Insert("FTPCompressOutgoingMessageFile",			"FTPСжиматьФайлИсходящегоСообщения");
	Descriptions.Insert("FTPConnectionMaximumValidMessageSize",	"FTPСоединениеМаксимальныйДопустимыйРазмерСообщения");
	Descriptions.Insert("FTPConnectionPassword",						"FTPСоединениеПароль");
	Descriptions.Insert("FTPConnectionPassiveConnection",			"FTPСоединениеПассивноеСоединение");
	Descriptions.Insert("FTPConnectionUser",						"FTPСоединениеПользователь");
	Descriptions.Insert("FTPConnectionPort",						"FTPСоединениеПорт");
	Descriptions.Insert("FTPConnectionPath",						"FTPСоединениеПуть");
	
	Descriptions.Insert("COMInfobaseOperationMode",					"COMВариантРаботыИнформационнойБазы");
	Descriptions.Insert("COMInfobaseNameAtServer1CEnterprise",	"COMИмяИнформационнойБазыНаСервере1СПредприятия");
	Descriptions.Insert("COMServerName1CEnterprise",					"COMИмяСервера1СПредприятия");
	Descriptions.Insert("COMInfobaseDirectory",							"COMКаталогИнформационнойБазы");
	Descriptions.Insert("COMAuthenticationOS",							"COMАутентификацияОперационнойСистемы");
	Descriptions.Insert("COMUserName",									"COMИмяПользователя");
	
	Descriptions.Insert("UseTransportParametersEMAIL",	"ИспользоватьПараметрыТранспортаEMAIL");
	Descriptions.Insert("UseTransportParametersFILE",		"ИспользоватьПараметрыТранспортаFILE");
	Descriptions.Insert("UseTransportParametersFTP",		"ИспользоватьПараметрыТранспортаFTP");
	
	Descriptions.Insert("ExchangeProcessingSettingName",	"НаименованиеНастройкиВыполненияОбмена");
	Descriptions.Insert("NewNodeCode",								"КодНовогоУзла");
	Descriptions.Insert("PredefinedNodeCode",					"КодПредопределенногоУзла");
	
	Return Descriptions;
	
EndFunction

Function ReceiverProp(Name, Value)
	
	Return New Structure("Name, Value",Name, Value);
	
EndFunction

Procedure AddXMLWriter(XMLWriter, AttributeName)

	ReceivValue = DataEcxhangeParameterDescription(AttributeName);
	If TypeOf(ReceivValue) = Type("Structure") Then
		RecAttrVal = ReceivValue.Value;
		RecAttrName = ReceivValue.Name;
	Else
		RecAttrName =  ReceivValue;
		RecAttrVal = ThisObject[AttributeName];
	EndIf;
	
	WriteXML(XMLWriter, RecAttrVal, RecAttrName, XMLTypeAssignment.Explicit);
	
EndProcedure

Procedure AddXMLWriterExeption(XMLWriter, AttributeName)
	
	AttributeValue = ThisObject[AttributeName];
	ReceiverAttributeProp = AttributeExceptionValue(AttributeValue);
	 
	//WriteXML(XMLWriter, AttributeValue, AttributeName, XMLTypeAssignment.Explicit);
	
	AttributeNameReceiver = DataEcxhangeParameterDescription(AttributeName);
	
	XMLWriter.WriteStartElement(AttributeNameReceiver);
	XMLWriter.WriteNamespaceMapping("xsi", "http://www.w3.org/2001/XMLSchema-instance");;
	XMLWriter.WriteAttribute("type", "http://www.w3.org/2001/XMLSchema-instance", ReceiverAttributeProp.Type);
	XMLWriter.WriteText(ReceiverAttributeProp.Value);
	XMLWriter.WriteEndElement();
	
EndProcedure

Function AttributeExceptionValue(AttributeValue)
	
	Exceptions = AttributeExceptionMaps();
	If Exceptions = Undefined Then
		ExceptionValue = AttributeValue
	Else
		ExceptionValue = Exceptions.Get(AttributeValue);
	EndIf;
	
	Return ExceptionValue;
	
EndFunction

Function AttributeExceptionMaps()
	
	ExceptionsMaps = ExceprionValues();
	Exceptions = ExceptionsMaps.Get(ExchangePlanName);
	
	Return Exceptions;
	
EndFunction

Function ExceprionValues()
	
	Result = New Map;
	Result.Insert("ExchangeCompanyManagementAccounting", MdValuesMap());
//	Result.Insert("ExchangeCompanyManagementAccounting40", MdValuesMap());
	
	Return Result;
	
EndFunction


Function MdValuesMap()
	
	ValuesMap = New Map;
	ValuesMap.Insert(Enums.ExchangeMessagesTransportKinds.EMAIL, 
		New Structure("Type, Value", "EnumRef.ВидыТранспортаСообщенийОбмена", "EMAIL"));
	ValuesMap.Insert(Enums.ExchangeMessagesTransportKinds.FILE, 
		New Structure("Type, Value", "EnumRef.ВидыТранспортаСообщенийОбмена", "FILE"));
	ValuesMap.Insert(Enums.ExchangeMessagesTransportKinds.FTP, 
		New Structure("Type, Value", "EnumRef.ВидыТранспортаСообщенийОбмена", "FTP"));
	ValuesMap.Insert(Enums.ExchangeMessagesTransportKinds.WS, 
		New Structure("Type, Value", "Enums.ВидыТранспортаСообщенийОбмена", "WS"));
	ValuesMap.Insert(Enums.ExchangeMessagesTransportKinds.COM, 
		New Structure("Type, Value", "EnumRef.ВидыТранспортаСообщенийОбмена", "COM"));
		
	//ValuesMap.Insert(Catalogs.EmailAccounts..COM, 
	//	New Structure("Type, Value", "EnumRef.ВидыТранспортаСообщенийОбмена", "COM"));

		
	Return ValuesMap;
	
EndFunction

Procedure DeleteTemporaryFile(TempFileName)
	
	If Not IsBlankString(TempFileName) Then
		
		DeleteFiles(TempFileName);
		
	EndIf;
	
EndProcedure

Procedure MessageInformationAboutError(ErrorInfo, Cancel)
	
	ErrorMessageStringField = DetailErrorDescription(ErrorInfo);
	
	DataExchangeServer.ShowMessageAboutError(BriefErrorDescription(ErrorInfo), Cancel);
	
	WriteLogEvent(DataExchangeServer.DataExchangeCreationEventLogMonitorMessageText(), EventLogLevel.Error,,, ErrorMessageString());
	
EndProcedure

Function GetFilterSettingsValues(ExternalConnectionSettingsStructure)
	
	Return DataExchangeServer.GetFilterSettingsValues(ExternalConnectionSettingsStructure);
	
EndFunction

Function ExchangeDataSettingsFileFormatVersion()
	
	Return "1.1";
	
EndFunction

Function ShieldEnums(Settings)
	
	Result = New Structure;
	
	For Each Setting IN Settings Do
		
		If CommonUse.ReferenceTypeValue(Setting.Value)
			AND CommonUse.ObjectKindByRef(Setting.Value) = "Enum" Then
			
			Result.Insert(Setting.Key, GetPredefinedValueFullName(Setting.Value));
			
		Else
			
			Result.Insert(Setting.Key, Setting.Value);
			
		EndIf;
		
	EndDo;
	
	Return Result;
EndFunction

#EndRegion

#EndIf
