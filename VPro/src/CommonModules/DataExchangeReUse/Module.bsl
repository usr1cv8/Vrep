////////////////////////////////////////////////////////////////////////////////
// Data exchange subsystem
// 
////////////////////////////////////////////////////////////////////////////////

#Region ProgramInterface

// It returns the flag of the exchange plan usage during data exchange.
// If the exchange plan contains at least one node
// except for the predefined one, then it is considered to be used.
//
// Parameters:
// ExchangePlanName - String - exchange plan name as specified in the designer.
// Sender - ExchangePlanRef - The parameter value is
// 				 	set if it is necessary to determine whether there
// 				 	are other nodes except the node from which the object was received.
//
// Returns:
//  True - exchange plan is used, False - no.
//
Function DataExchangeEnabled(Val ExchangePlanName, Val Sender = Undefined) Export
	
	QueryText = "SELECT TOP 1 1
	|FROM
	|	ExchangePlan." + ExchangePlanName + " AS
	|ExchangePlan
	|WHERE ExchangePlan.Ref
	|	<> &ThisNode AND ExchangePlan.Ref <> &Sender";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("ThisNode", ExchangePlans[ExchangePlanName].ThisNode());
	Query.SetParameter("Sender", Sender);
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

// It returns True if the session is running in the offline workplace.
//
Function ThisIsOfflineWorkplace() Export
	
	SetPrivilegedMode(True);
	
	If Constants.SubordinatedDIBNodeSettingsFinished.Get() Then
		
		Return Constants.ThisIsOfflineWorkplace.Get();
		
	Else
		
		Return DataExchangeServer.MasterNode() <> Undefined
			AND DataExchangeReUse.OfflineWorkSupported()
			AND DataExchangeServer.MasterNode().Metadata().Name = DataExchangeReUse.OfflineWorkExchangePlan();
		
	EndIf;
	
EndFunction

#EndRegion

#Region ServiceProgramInterface

////////////////////////////////////////////////////////////////////////////////
// Object recording mechanism at the exchange plan nodes (ORM).

// It receives this infobase name from the Constant or the configuration synonym.
// (For internal use only).
//
Function ThisInfobaseName() Export
	
	SetPrivilegedMode(True);
	
	Result = Constants.SystemTitle.Get();
	
	If IsBlankString(Result) Then
		
		Result = Metadata.Synonym;
		
	EndIf;
	
	Return Result;
EndFunction

// It receives the code of the predefined exchange plan node.
// 
// Parameters:
//  ExchangePlanName - String - exchange plan name as specified in the designer.
// 
// Returns:
//  String - code of the exchange plan predefined node.
//
Function GetThisNodeCodeForExchangePlan(ExchangePlanName) Export
	
	Return CommonUse.ObjectAttributeValue(GetThisNodeOfExchangePlan(ExchangePlanName), "Code");
	
EndFunction

// It receives the predefined exchange plan node description.
// 
// Parameters:
//  InfobaseNode - ExchangePlanRef - exchange plan node.
// 
// Returns:
//  String - predefined exchange plan node description.
//
Function ThisNodeDescription(Val InfobaseNode) Export
	
	Return CommonUse.ObjectAttributeValue(GetThisNodeOfExchangePlan(GetExchangePlanName(InfobaseNode)), "Description");
	
EndFunction

// It receives the array of the configuration exchange plan names that use SSL functionality.
// 
// Parameters:
//  No.
// 
// Returns:
// Array - array of the exchange plan name items.
//
Function SSLExchangePlans() Export
	
	Return SLExchangePlanList().UnloadValues();
	
EndFunction

// Outdated. IN the future it is required to use SetExternalConnectionWithBase.
//
Function EstablishExternalConnection(ExternalConnectionParameters, ErrorMessageString = "") Export

	Result = InstallOuterDatabaseJoin(ExternalConnectionParameters);
	ErrorMessageString = Result.DetailedErrorDescription;

	Return Result.Join;
EndFunction

// It connects externally with the infobase and returns the connection description.
// (For internal use only).
//
// Parameters:
//    Parameters - Structure - For the external connection
//                             parameters see CommonUse.SetExternalConnectionWthBase.
//
Function InstallOuterDatabaseJoin(Parameters) Export
	
	// Convert settings - parameters of external connection to transport parameters.
	TransportSettings = DataExchangeServer.TransportSettingsByExternalConnectionParameters(Parameters);
	Return DataExchangeServer.InstallOuterDatabaseJoin(TransportSettings);
EndFunction

// It determines if the exchange plan identified by the name is used in the service model.
// To provide the possibility to determine it all exchange plans define the ExchangePlanUsedSaaS function
// clearly returning True or False value at the manager module level.
//
// Parameters:
// ExchangePlanName - String.
//
// Returns:
// Boolean.
//
Function ExchangePlanUsedSaaS(Val ExchangePlanName) Export
	
	Result = False;
	
	If SSLExchangePlans().Find(ExchangePlanName) <> Undefined Then
		
		Result = ExchangePlans[ExchangePlanName].ExchangePlanUsedSaaS();
		
	EndIf;
	
	Return Result;
EndFunction

// Defines if the exchange plan is included to the list of exchange plans that use data exchange according to XDTO format.
//
// Parameters:
//  ExchangePlan - Ref to exchange plan node or exchange plan name.
//
// Return value: Boolean.
//
Function ThisIsExchangePlanXDTO(ExchangePlan) Export
	If TypeOf(ExchangePlan) = Type("String") Then
		ExchangePlanName = ExchangePlan;
	Else
		ExchangePlanName = ExchangePlan.Metadata().Name;
	EndIf;
	Return DataExchangeServer.ExchangePlanSettingValue(ExchangePlanName, "ThisIsExchangePlanXDTO");
EndFunction

// It defines the version number of the synchronized object accounting subsystem for the infobase node.
//
// Parameters:
//  InfobaseNode - ExchangePlansRef.
//
// Returns - Number, version number
//           1 - using InfobaseObjectsMatching register 
//           2 - using SynchronizedObjectPublicIDs and ObjectDataForRecordingInExchanges registers.
// 
//
Function SynchronizedObjectsAccountingSubsystemVersion(Val InfobaseNode) Export
	//Query = New Query("
	//|SELECT TOP 1 
	//|	1
	//|FROM 
	//|	InformationRegister.InfobasesObjectsCompliance
	//|WHERE 
	//|	InfobaseNode = &InfobaseNode");
	//Query.SetParameter("InfobaseNode", InfobaseNode);
	//QueryResult = Query.Execute();
	Return 2;
EndFunction

// It fills the list of possible error codes.
//
// Returns:
//  Matching. Key - error code number value - error description (string).
//
Function ErrorMessages() Export
	
	ErrorMessages = New Map;
		
	ErrorMessages.Insert(2,  NStr("en='An error occurred when unpacking an exchange file. The file is locked.';ru='Ошибка распаковки файла обмена. Файл заблокирован.';vi='Lỗi khi giải nén tệp trao đổi. Tệp bị khóa.'"));
	ErrorMessages.Insert(3,  NStr("en='The specified exchange rule file does not exist.';ru='Указанный файл правил обмена не существует.';vi='Tệp quy tắc trao đổi đã chọn không tồn tại.'"));
	ErrorMessages.Insert(4,  NStr("en='An error occurred when creating COM object Msxml2.DOMDocument';ru='Ошибка при создании COM-объекта Msxml2.DOMDocument';vi='Lỗi khi tạo COM-объекта Msxml2.DOMDocument'"));
	ErrorMessages.Insert(5,  NStr("en='An error occurred when opening the exchange file';ru='Ошибка открытия файла обмена';vi='Lỗi mở tệp trao đổi'"));
	ErrorMessages.Insert(6,  NStr("en='An error occurred when importing exchange rules';ru='Ошибка при загрузке правил обмена';vi='Lỗi khi kết nhập quy tắc trao đổi'"));
	ErrorMessages.Insert(7,  NStr("en='Error in exchange rule format';ru='Ошибка формата правил обмена';vi='Lỗi định dạng quy tắc trao đổi'"));
	ErrorMessages.Insert(8,  NStr("en='Incorrect file name for data export';ru='Не корректно указано имя файла для выгрузки данных';vi='Đã chỉ ra không đúng tên tệp để kết xuất dữ liệu'"));
	ErrorMessages.Insert(9,  NStr("en='Error in exchange file format';ru='Ошибка формата файла обмена';vi='Lỗi định dạng tệp trao đổi'"));
	ErrorMessages.Insert(10, NStr("en='File name for data export is not specified (Data file name)';ru='Не указано имя файла для выгрузки данных (Имя файла данных)';vi='Chưa chỉ ra tên tệp để kết xuất dữ liệu (Tên tệp dữ liệu)'"));
	ErrorMessages.Insert(11, NStr("en='Link to a non-existing metadata object in the exchange rules';ru='Ссылка на несуществующий объект метаданных в правилах обмена';vi='Tham chiếu đến đối tượng Metadata không tồn tại trong các quy tắc trao đổi'"));
	ErrorMessages.Insert(12, NStr("en='File name with exchange rules is not specified (Rule file name)';ru='Не указано имя файла с правилами обмена (Имя файла правил)';vi='Chưa chỉ ra tên tệp với các quy tắc trao đổi (Tên tệp quy tắc)'"));
			
	ErrorMessages.Insert(13, NStr("en='An error occurred when receiving a value of the object property (by the name of the source property)';ru='Ошибка получения значения свойства объекта (по имени свойства источника)';vi='Lỗi nhận giá trị thuộc tính đối tượng (theo tên thuộc tính nguồn)'"));
	ErrorMessages.Insert(14, NStr("en='An error occurred when receiving the object property value (by the target property name)';ru='Ошибка получения значения свойства объекта (по имени свойства приемника)';vi='Lỗi nhận giá trị thuộc tính đối tượng (theo tên thuộc tính đích)'"));
	
	ErrorMessages.Insert(15, NStr("en='File name for data import is not specified (File name for import)';ru='Не указано имя файла для загрузки данных (Имя файла для загрузки)';vi='Chưa chỉ ra tên tệp để kết nhập dữ liệu (Tên tệp để kết nhập)'"));
			
	ErrorMessages.Insert(16, NStr("en='An error occurred while receiving value of subobject property (by source property name)';ru='Ошибка получения значения свойства подчиненного объекта (по имени свойства источника)';vi='Lỗi nhận giá trị thuộc tính đối tượng trực thuộc (theo tên thuộc tính nguồn)'"));
	ErrorMessages.Insert(17, NStr("en='An error occurred while receiving value of subobject property (by target property name)';ru='Ошибка получения значения свойства подчиненного объекта (по имени свойства приемника)';vi='Lỗi nhận giá trị thuộc tính đối tượng trực thuộc (theo tên thuộc tính đích)'"));
	ErrorMessages.Insert(18, NStr("en='An error occurred when creating a data processor with the handler code';ru='Ошибка при создании обработки с кодом обработчиков';vi='Lỗi khi tạo mới bộ xử lý có mã hàm sự kiện'"));
	ErrorMessages.Insert(19, NStr("en='An error occurred in event handler BeforeObjectImport';ru='Ошибка в обработчике события ПередЗагрузкойОбъекта';vi='Lỗi trong hàm sự kiện BeforeObjectImport'"));
	ErrorMessages.Insert(20, NStr("en='An error occurred in event handler OnObjectImport';ru='Ошибка в обработчике события ПриЗагрузкеОбъекта';vi='Lỗi trong hàm sự kiện OnObjectImport'"));
	ErrorMessages.Insert(21, NStr("en='An error occurred in event handler AfterObjectImport';ru='Ошибка в обработчике события ПослеЗагрузкиОбъекта';vi='Lỗi trong hàm sự kiện AfterObjectImport'"));
	ErrorMessages.Insert(22, NStr("en='An error occurred in event handler BeforeDataImport (conversion)';ru='Ошибка в обработчике события ПередЗагрузкойДанных (конвертация)';vi='Lỗi trong hàm sự kiện BeforeDataImport (chuyển đổi)'"));
	ErrorMessages.Insert(23, NStr("en='An error occurred in event handler AfterDataImport (conversion)';ru='Ошибка в обработчике события ПослеЗагрузкиДанных (конвертация)';vi='Lỗi trong hàm sự kiện AfterDataImport (chuyển đổi)'"));
	ErrorMessages.Insert(24, NStr("en='An error occurred when removing an object';ru='Ошибка при удалении объекта';vi='Lỗi khi xóa đối tượng'"));
	ErrorMessages.Insert(25, NStr("en='An error occurred when writing the document';ru='Ошибка при записи документа';vi='Lỗi khi ghi chứng từ'"));
	ErrorMessages.Insert(26, NStr("en='An error occurred when writing the object';ru='Ошибка записи объекта';vi='Lỗi ghi đối tượng'"));
	ErrorMessages.Insert(27, NStr("en='An error occurred in event handler BeforeProcessClearingRule';ru='Ошибка в обработчике события ПередОбработкойПравилаОчистки';vi='Lỗi trong hàm sự kiện BeforeProcessClearingRule'"));
	ErrorMessages.Insert(28, NStr("en='An error occurred in event handler AfterClearingRuleProcessing';ru='Ошибка в обработчике события ПослеОбработкиПравилаОчистки';vi='Lỗi trong hàm sự kiện AfterClearingRuleProcessing'"));
	ErrorMessages.Insert(29, NStr("en='An error occurred in event handler BeforeDeleteObject';ru='Ошибка в обработчике события ПередУдалениемОбъекта';vi='Lỗi trong hàm sự kiện BeforeDeleteObject'"));
	
	ErrorMessages.Insert(31, NStr("en='An error occurred in event handler BeforeProcessExportRule';ru='Ошибка в обработчике события ПередОбработкойПравилаВыгрузки';vi='Lỗi trong hàm sự kiện BeforeProcessExportRule'"));
	ErrorMessages.Insert(32, NStr("en='An error occurred in event handler AfterDumpRuleProcessing';ru='Ошибка в обработчике события ПослеОбработкиПравилаВыгрузки';vi='Lỗi trong hàm sự kiện AfterDumpRuleProcessing'"));
	ErrorMessages.Insert(33, NStr("en='An error occurred in event handler BeforeObjectExport';ru='Ошибка в обработчике события ПередВыгрузкойОбъекта';vi='Lỗi trong hàm sự kiện BeforeObjectExport'"));
	ErrorMessages.Insert(34, NStr("en='An error occurred in event handler AfterObjectExport';ru='Ошибка в обработчике события ПослеВыгрузкиОбъекта';vi='Lỗi trong hàm sự kiện AfterObjectExport'"));
			
	ErrorMessages.Insert(41, NStr("en='An error occurred in event handler BeforeObjectExport';ru='Ошибка в обработчике события ПередВыгрузкойОбъекта';vi='Lỗi trong hàm sự kiện BeforeObjectExport'"));
	ErrorMessages.Insert(42, NStr("en='An error occurred in event handler OnObjectExport';ru='Ошибка в обработчике события ПриВыгрузкеОбъекта';vi='Lỗi trong hàm sự kiện OnObjectExport'"));
	ErrorMessages.Insert(43, NStr("en='An error occurred in event handler AfterObjectExport';ru='Ошибка в обработчике события ПослеВыгрузкиОбъекта';vi='Lỗi trong hàm sự kiện AfterObjectExport'"));
			
	ErrorMessages.Insert(45, NStr("en='Object conversion rule is not found';ru='Не найдено правило конвертации объектов';vi='Không tìm thấy quy tắc chuyển đổi đối tượng'"));
		
	ErrorMessages.Insert(48, NStr("en='An error occurred in event handler BeforeExportProcessor of the property group';ru='Ошибка в обработчике события ПередОбработкойВыгрузки группы свойств';vi='Lỗi trong hàm sự kiện BeforeExportProcessor nhóm thuộc tính'"));
	ErrorMessages.Insert(49, NStr("en='An error occurred in event handler AfterExportProcessor of the property group';ru='Ошибка в обработчике события ПослеОбработкиВыгрузки группы свойств';vi='Lỗi trong hàm sự kiện AfterExportProcessor nhóm thuộc tính'"));
	ErrorMessages.Insert(50, NStr("en='Error in event handler BeforeExport (of collection object)';ru='Ошибка в обработчике события ПередВыгрузкой (объекта коллекции)';vi='Lỗi trong hàm sự kiện BeforeExport (đối tượng tập hợp)'"));
	ErrorMessages.Insert(51, NStr("en='Error in event handler OnExport (of collection object)';ru='Ошибка в обработчике события ПриВыгрузке (объекта коллекции)';vi='Lỗi trong hàm sự kiện OnExport (đối tượng tập hợp)'"));
	ErrorMessages.Insert(52, NStr("en='Error in event handler AfterExport (of collection object)';ru='Ошибка в обработчике события ПослеВыгрузки (объекта коллекции)';vi='Lỗi trong hàm sự kiện AfterExport (đối tượng tập hợp)'"));
	ErrorMessages.Insert(53, NStr("en='An error occurred in global event handler BeforeObjectImporting (conversion)';ru='Ошибка в глобальном обработчике события ПередЗагрузкойОбъекта (конвертация)';vi='Lỗi trong hàm sự kiện toàn cục BeforeObjectImporting (chuyển đổi)'"));
	ErrorMessages.Insert(54, NStr("en='An error occurred in global event handler AfterObjectImport (conversion)';ru='Ошибка в глобальном обработчике события ПослеЗагрузкиОбъекта (конвертация)';vi='Lỗi trong hàm sự kiện toàn cục AfterObjectImport (chuyển đổi)'"));
	ErrorMessages.Insert(55, NStr("en='An error occurred in event handler BeforeExport (properties)';ru='Ошибка в обработчике события ПередВыгрузкой (свойства)';vi='Lỗi trong hàm sự kiện BeforeExport (thuộc tính)'"));
	ErrorMessages.Insert(56, NStr("en='An error occurred in event handler OnExport (properties)';ru='Ошибка в обработчике события OnExport (свойства)';vi='Lỗi trong hàm sự kiện OnExport (thuộc tính)'"));
	ErrorMessages.Insert(57, NStr("en='An error occurred in event handler AfterExport (properties)';ru='Ошибка в обработчике события ПослеВыгрузки (свойства)';vi='Lỗi trong hàm sự kiện AfterExport (thuộc tính)'"));
	
	ErrorMessages.Insert(62, NStr("en='An error occurred in event handler BeforeDataExport (conversion)';ru='Ошибка в обработчике события ПередВыгрузкойДанных (конвертация)';vi='Lỗi trong hàm sự kiện BeforeDataExport (chuyển đổi)'"));
	ErrorMessages.Insert(63, NStr("en='An error occurred in event handler AfterDataExport (conversion)';ru='Ошибка в обработчике события ПослеВыгрузкиДанных (конвертация)';vi='Lỗi trong hàm sự kiện AfterDataExport (chuyển đổi)'"));
	ErrorMessages.Insert(64, NStr("en='An error occurred in global event handler BeforeObjectConversion (conversion)';ru='Ошибка в глобальном обработчике события ПередКонвертациейОбъекта (конвертация)';vi='Lỗi trong hàm sự kiện toàn cục BeforeObjectConversion (chuyển đổi)'"));
	ErrorMessages.Insert(65, NStr("en='An error occurred in global event handler BeforeObjectExport (conversion)';ru='Ошибка в глобальном обработчике события ПередВыгрузкойОбъекта (конвертация)';vi='Lỗi trong hàm sự kiện toàn cục BeforeObjectExport (chuyển đổi)'"));
	ErrorMessages.Insert(66, NStr("en='An error occurred when receiving a subordinate object collection from the incoming data';ru='Ошибка получения коллекции подчиненных объектов из входящих данных';vi='Lỗi nhận tập hợp đối tượng trực thuộc từ dữ liệu đến'"));
	ErrorMessages.Insert(67, NStr("en='An error occurred when receiving the subordinate object properties from the incoming data';ru='Ошибка получения свойства подчиненного объекта из входящих данных';vi='Lỗi nhận thuộc tính đối tượng trực thuộc từ dữ liệu đến'"));
	ErrorMessages.Insert(68, NStr("en='An error occurred when receiving the object properties from the incoming data';ru='Ошибка получения свойства объекта из входящих данных';vi='Lỗi nhận thuộc tính đối tượng từ dữ liệu đến'"));
	
	ErrorMessages.Insert(69, NStr("en='An error occurred in global event handler AfterObjectExport (conversion)';ru='Ошибка в глобальном обработчике события ПослеВыгрузкиОбъекта (конвертация)';vi='Lỗi trong hàm sự kiện toàn cục AfterObjectExport (chuyển đổi)'"));
	
	ErrorMessages.Insert(71, NStr("en='Match for the Source value is not found';ru='Не найдено соответствие для значения Источника';vi='Không tìm thấy sự tương ứng đối với giá trị Nguồn'"));
	
	ErrorMessages.Insert(72, NStr("en='An error occurred when exporting data for the exchange plan node';ru='Ошибка при выгрузке данных для узла плана обмена';vi='Lỗi khi kết xuất dữ liệu đối với nút của sơ đồ trao đổi'"));
	
	ErrorMessages.Insert(73, NStr("en='An error occurred in event handler SearchFieldsSequence';ru='Ошибка в обработчике события ПоследовательностьПолейПоиска';vi='Lỗi trong hàm sự kiện SearchFieldsSequence'"));
	ErrorMessages.Insert(74, NStr("en='Import exchange rules for data export again.';ru='Необходимо перезагрузить правила обмена для выгрузки данных.';vi='Cần kết nhập lại quy tắc trao đổi để kết xuất dữ liệu.'"));
	
	ErrorMessages.Insert(75, NStr("en='An error occurred in event handler AfterImportOfExchangeRules (conversion)';ru='Ошибка в обработчике события ПослеЗагрузкиПравилОбмена (конвертация)';vi='Lỗi trong hàm sự kiện AfterImportOfExchangeRules (chuyển đổi)'"));
	ErrorMessages.Insert(76, NStr("en='An error occurred in event handler BeforeSendingUninstallInformation (conversion)';ru='Ошибка в обработчике события ПередОтправкойИнформацииОбУдалении (конвертация)';vi='Lỗi trong hàm sự kiện BeforeSendingUninstallInformation (chuyển đổi)'"));
	ErrorMessages.Insert(77, NStr("en='An error occurred in event handler OnObtainingInformationAboutDeletion (conversion)';ru='Ошибка в обработчике события ПриПолученииИнформацииОбУдалении (конвертация)';vi='Lỗi trong hàm sự kiện OnObtainingInformationAboutDeletion (chuyển đổi)'"));
	
	ErrorMessages.Insert(78, NStr("en='An error occurred when executing the algorithm after import of the parameter values';ru='Ошибка при выполнении алгоритма после загрузки значений параметров';vi='Lỗi khi thực hiện thuật toán sau khi kết nhập giá trị tham số'"));
	
	ErrorMessages.Insert(79, NStr("en='An error occurred in event handler AfterObjectExportToFile';ru='Ошибка в обработчике события ПослеВыгрузкиОбъектаВФайл';vi='Lỗi trong hàm sự kiện AfterObjectExportToFile'"));
	
	ErrorMessages.Insert(80, NStr("en='Error of the predefined item property setting."
"You can not mark the predefined item to be deleted. Mark for deletion for the objects is not installed.';ru='Ошибка установки свойства предопределенного элемента."
"Нельзя помечать на удаление предопределенный элемент. Пометка на удаление для объекта не установлена.';vi='Lỗi thiết lập thuộc tính của phần tử định trước."
"Không nên đánh dấu xóa phần tử định trước. Việc đánh dấu xóa cho đối tượng không được thiết lập.'"));
	//
	ErrorMessages.Insert(81, NStr("en='The object change collision occurred."
"This infobase object has been replaced by the second infobase object version.';ru='Возникла коллизия изменений объектов."
"Объект этой информационной базы был заменен версией объекта из второй информационной базы.';vi='Xuất hiện xung đột thay đổi các đối tượng."
"Đối tượng của cơ sở thông tin này đã được thay thế bởi phiên bản đối tượng từ cơ sở thông tin thứ hai.'"));
	//
	ErrorMessages.Insert(82, NStr("en='The object change collision occurred."
"Object from the second infobase is not accepted. This infobase object has not been modified.';ru='Возникла коллизия изменений объектов."
"Объект из второй информационной базы не принят. Объект этой информационной базы не изменен.';vi='Xuất hiện xung đột khi thay đổi đối tượng."
"Đối tượng từ cơ sở thông tin thứ hai chưa được tiếp nhận, Đối tượng của cơ sở thông tin này không thay đổi.'"));
	//
	ErrorMessages.Insert(83, NStr("en='An error occurred while accessing the object tabular section. The object tabular section cannot be changed.';ru='Ошибка обращения к табличной части объекта. Табличная часть объекта не может быть изменена.';vi='Lỗi truy cập đến phần bảng đối tượng. Không thể thay đổi phần bảng đối tượng.'"));
	ErrorMessages.Insert(84, NStr("en='Collision of change closing dates.';ru='Коллизия дат запрета изменения.';vi='Mâu thuẫn ngày cấm thay đổi.'"));
	
	ErrorMessages.Insert(174, NStr("en='Exchange message was previously received';ru='Сообщение обмена было принято ранее';vi='Đã tiếp nhận thông điệp trao đổi trước đây'"));
	ErrorMessages.Insert(175, NStr("en='Exchange plan name from the exchange message is not as expected.';ru='Имя плана обмена из сообщения обмена не соответствует ожидаемому.';vi='Tên sơ đồ trao đổi từ thông báo trao đổi không tương ứng với tên mong muốn.'"));
	ErrorMessages.Insert(176, NStr("en='Recipient from the exchange message is not as expected.';ru='Получатель из сообщения обмена не соответствует ожидаемому.';vi='Người nhận từ thông báo trao đổi không như mong muốn.'"));
		
	ErrorMessages.Insert(177, NStr("en='Exchange plan name from the exchange message is not as expected.';ru='Имя плана обмена из сообщения обмена не соответствует ожидаемому.';vi='Tên sơ đồ trao đổi từ thông báo trao đổi không tương ứng với tên mong muốn.'"));
	ErrorMessages.Insert(178, NStr("en='Recipient from the exchange message is not as expected.';ru='Получатель из сообщения обмена не соответствует ожидаемому.';vi='Người nhận từ thông báo trao đổi không như mong muốn.'"));
	
	ErrorMessages.Insert(1000, NStr("en='An error occurred when creating a temporary file of data export';ru='Ошибка при создании временного файла выгрузки данных';vi='Lỗi khi tạo tệp tạm thời kết xuất dữ liệu'"));
	
	Return ErrorMessages;
	
EndFunction


// For an internal use.
//
Function OfflineWorkSupported() Export
	
	Return OfflineWorkExchangePlans().Count() = 1;
	
EndFunction

// For an internal use.
//
Function OfflineWorkExchangePlan() Export
	
	Result = OfflineWorkExchangePlans();
	
	If Result.Count() = 0 Then
		
		Raise NStr("en='Offline work in the application is not supported.';ru='Автономная работа в системе не предусмотрена.';vi='Không xem xét làm việc độc lập trong hệ thống.'");
		
	ElsIf Result.Count() > 1 Then
		
		Raise NStr("en='More than one exchange plan for offline work was created.';ru='Создано более одного плана обмена для автономной работы.';vi='Tạo ra nhiều hơn một sơ đồ trao đổi để làm việc độc lập.'");
		
	EndIf;
	
	Return Result[0];
EndFunction

// It determines whether the transferred exchange plan node is the offline workplace.
//
Function ThisIsNodeOfOfflineWorkplace(Val InfobaseNode) Export
	
	Return DataExchangeReUse.OfflineWorkSupported()
		AND InfobaseNode.Metadata().Name = DataExchangeReUse.OfflineWorkExchangePlan()
	;
EndFunction

//

// For an internal use.
//
Function FindExchangePlanNodeByCode(ExchangePlanName, NodeCode) Export
	
	QueryText =
	"SELECT
	|	ExchangePlan.Ref AS Ref
	|FROM
	|	ExchangePlan.[ExchangePlanName] AS ExchangePlan
	|WHERE
	|	ExchangePlan.Code = &Code";
	
	QueryText = StrReplace(QueryText, "[ExchangePlanName]", ExchangePlanName);
	
	Query = New Query;
	Query.SetParameter("Code", NodeCode);
	Query.Text = QueryText;
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		
		Return Undefined;
		
	EndIf;
	
	Selection = QueryResult.Select();
	Selection.Next();
	
	Return Selection.Ref;
EndFunction

#EndRegion

#Region ServiceProceduresAndFunctions

////////////////////////////////////////////////////////////////////////////////
// Object recording mechanism at the exchange plan nodes (ORM).

// It receives the table of the object recording rules for the exchange plan.
// 
// Parameters:
//  ExchangePlanName - String - the exchange plan name as specified
//                     in the designer for which you shall receive the recording rules.
// 
// Returns:
// Values table - rules table registration for current plan exchange.
//
Function ExchangePlanObjectChangeRecordRules(Val ExchangePlanName) Export
	
	ObjectRegistrationRules = DataExchangeServerCall.SessionParametersObjectRegistrationRules().Get();
	
	Return ObjectRegistrationRules.Copy(New Structure("ExchangePlanName", ExchangePlanName));
EndFunction

// It receives the table of the object recording rules for the specified exchange plan.
// 
// Parameters:
//  ExchangePlanName   - String - exchange plan name as specified in the designer.
//  FullObjectName - String - Full name
//                   of the metadata object for which you shall receive the recording rules.
// 
// Returns:
// Values table - table of object recording rules based on the specified exchange plan.
//
Function ObjectChangeRecordRules(Val ExchangePlanName, Val FullObjectName) Export
	
	ExchangePlanObjectChangeRecordRules = DataExchangeEvents.ExchangePlanObjectChangeRecordRules(ExchangePlanName);
	
	Return ExchangePlanObjectChangeRecordRules.Copy(New Structure("MetadataObjectName", FullObjectName));
	
EndFunction

// It returns the flag showing that the object recording rules based on a specified exchange plan exist.
// 
// Parameters:
//  ExchangePlanName   - String - exchange plan name as specified in the designer.
//  FullObjectName - String - full name of
//                   the metadata object for which you shall define the flag of recording rules availability.
// 
//  Returns:
//  True - recording rules for the object exist; False - no.
//
Function ObjectChangeRecordRulesExist(Val ExchangePlanName, Val FullObjectName) Export
	
	Return DataExchangeEvents.ObjectChangeRecordRules(ExchangePlanName, FullObjectName).Count() <> 0;
	
EndFunction

// It defines the metadata object autorecording flag in the exchange plan.
//
// Parameters:
//  ExchangePlanName   - String - exchange plan name as specified in the designer including the
//                                metadata object.
//  FullObjectName     - String - full name of the metadata object for which you shall receive the autorecording flag.
//
//  Returns:
//   True  - metadata object has Allowed autorecording flag in the exchange plan;
//   False - The metadata object has Prohibited autorecording flag in the
//           exchange plan or the metadata object is not included in the exchange plan.
//
Function AutoRecordPermitted(Val ExchangePlanName, Val FullObjectName) Export
	
	ExchangePlanContentItem = Metadata.ExchangePlans[ExchangePlanName].Content.Find(Metadata.FindByFullName(FullObjectName));
	
	If ExchangePlanContentItem = Undefined Then
		Return False; // Metadata object is not included in the exchange plan.
	EndIf;
	
	Return ExchangePlanContentItem.AutoRecord = AutoChangeRecord.Allow;
EndFunction

// It defines the flag of the metadata object inclusion to the exchange plan.
// 
// Parameters:
//  ExchangePlanName   - String - exchange plan name as specified in the designer.
//  FullObjectName     - String - metadata object full name for which it is necessary to receive the flag.
// 
//  Returns:
//   True - the object is included in the exchange plan; False - is not included.
//
Function ExchangePlanContainsObject(Val ExchangePlanName, Val FullObjectName) Export
	
	ExchangePlanContentItem = Metadata.ExchangePlans[ExchangePlanName].Content.Find(Metadata.FindByFullName(FullObjectName));
	
	Return ExchangePlanContentItem <> Undefined;
EndFunction

// It returns the list of the exchange plans containing at least one exchange node (ignoring ThisNode).
//
Function UsedExchangePlans() Export
	
	Return DataExchangeServer.GetExchangePlansBeingUsed();
	
EndFunction

// It returns the exchange plan content specified by the user.
// User content of the exchange plan
// is defined by the object recording rules and node settings selected by the user.
//
// Parameters:
//  Recipient - ExchangePlanRef - reference to
//              the exchange plan node for which you shall receive the user content of the exchange plan.
//
//  Returns:
//   Map:
//     * Key   - String - metadata object full name included in the exchange plan;
//     * Value - EnumRef.ExchangeObjectsExportModes - object exporting mode.
//
Function UserExchangePlanContent(Val Recipient) Export
	
	Result = New Map;
	
	TargetProperties = CommonUse.ObjectAttributesValues(Recipient,
		CommonUse.NamesOfAttributesByType(Recipient, Type("EnumRef.ExchangeObjectsExportModes")));
	
	Priorities = PrioritiesOfExportingsObjects();
	ExchangePlanName = Recipient.Metadata().Name;
	Rules = DataExchangeReUse.ExchangePlanObjectChangeRecordRules(ExchangePlanName);
	
	For Each Item IN Metadata.ExchangePlans[ExchangePlanName].Content Do
		
		ObjectName = Item.Metadata.FullName();
		ObjectRules = Rules.FindRows(New Structure("MetadataObjectName", ObjectName));
		ModeExporting = Undefined;
		
		If ObjectRules.Count() = 0 Then // Registration Rules are not set.
			
			ModeExporting = Enums.ExchangeObjectsExportModes.AlwaysExport;
			
		Else // recording rules are set
			
			For Each ORR IN ObjectRules Do
				
				If ValueIsFilled(ORR.FlagAttributeName) Then
					ModeExporting = MaximumObjectExportMode(TargetProperties[ORR.FlagAttributeName], ModeExporting, Priorities);
				EndIf;
				
			EndDo;
			
			If ModeExporting = Undefined
				OR ModeExporting = Enums.ExchangeObjectsExportModes.EmptyRef() Then
				ModeExporting = Enums.ExchangeObjectsExportModes.ExportByCondition;
			EndIf;
			
		EndIf;
		
		Result.Insert(ObjectName, ModeExporting);
		
	EndDo;
	
	Return Result;
EndFunction

// It returns the object exporting mode based on the user content of the exchange plan (user settings).
//
// Parameters:
//  ObjectName - Metadata object full name for which it is necessary to receive the exporting mode.;
//  Recipient  - ExchangePlanRef - reference to the exchange plan node which user content shall be used.
//
// Returns:
//   EnumRef.ExchangeObjectsExportModes - object exporting mode.
//
Function ObjectExportMode(Val ObjectName, Val Recipient) Export
	
	Result = DataExchangeReUse.UserExchangePlanContent(Recipient).Get(ObjectName);
	
	Return ?(Result = Undefined, Enums.ExchangeObjectsExportModes.AlwaysExport, Result);
EndFunction

Function MaximumObjectExportMode(Val ExportMode1, Val ExportMode2, Val Priorities)
	
	If Priorities.Find(ExportMode1) < Priorities.Find(ExportMode2) Then
		
		Return ExportMode1;
		
	Else
		
		Return ExportMode2;
		
	EndIf;
	
EndFunction

Function PrioritiesOfExportingsObjects()
	
	Result = New Array;
	Result.Add(Enums.ExchangeObjectsExportModes.AlwaysExport);
	Result.Add(Enums.ExchangeObjectsExportModes.ExportManually);
	Result.Add(Enums.ExchangeObjectsExportModes.ExportByCondition);
	Result.Add(Enums.ExchangeObjectsExportModes.EmptyRef());
	Result.Add(Enums.ExchangeObjectsExportModes.ExportIfNecessary);
	Result.Add(Enums.ExchangeObjectsExportModes.DoNotExport);
	Result.Add(Undefined);
	
	Return Result;
EndFunction

//

// It receives the table of the object recording attributes for the mechanism of object selective recording.
//
// Parameters:
//  ObjectName       - String - Metadata object full name, for example Catalog.ProductsAndServices.
//  ExchangePlanName - String - exchange plan name as specified in the designer.
//
// Returns:
//  ChangeRecordAttributeTable - values table - recording attribute table
// arranged by the Order field for the specified metadata object.
//
Function GetRegistrationAttributesTable(ObjectName, ExchangePlanName) Export
	
	ObjectChangeRecordAttributeTable = DataExchangeServer.GetSelectiveObjectRegistrationRulesSP();
	
	Filter = New Structure;
	Filter.Insert("ExchangePlanName", ExchangePlanName);
	Filter.Insert("ObjectName",     ObjectName);
	
	ChangeRecordAttributeTable = ObjectChangeRecordAttributeTable.Copy(Filter);
	
	ChangeRecordAttributeTable.Sort("Order Asc");
	
	Return ChangeRecordAttributeTable;
	
EndFunction

// It receives the table of object selective recording rules from the session parameters.
// 
// Parameters:
// No.
// 
// Returns:
// Values table - recording attribute table for all metadata objects.
//
Function GetSelectiveObjectRegistrationRulesSP() Export
	
	SetPrivilegedMode(True);
	
	Return SessionParameters.SelectiveObjectRegistrationRules.Get();
	
EndFunction

// It receives predefined exchange plan node.
// 
// Parameters:
//  ExchangePlanName - String - exchange plan name as specified in the designer.
// 
// Returns:
//  ThisNode - ExchangePlanRef - predefined exchange plan node.
//
Function GetThisNodeOfExchangePlan(ExchangePlanName) Export
	
	Return ExchangePlans[ExchangePlanName].ThisNode()
	
EndFunction

// It receives the predefined exchange plan node by the reference to the exchange plan node.
// 
// Parameters:
//  ExchangePlanNode - ExchangePlanRef - any exchange plan node.
// 
// Returns:
//  ThisNode - ExchangePlanRef - predefined exchange plan node.
//
Function GetThisNodeOfExchangePlanByRef(ExchangePlanNode) Export
	
	Return GetThisNodeOfExchangePlan(GetExchangePlanName(ExchangePlanNode));
	
EndFunction

// It returns the flag of the node belonging to DIB exchange plan.
// 
// Parameters:
//  InfobaseNode - ExchangePlanRef - exchange plan node for which it is necessary to receive the funcion value.
// 
//  Returns:
//   True - the node belongs to DIB exchange plan, otherwise False.
//
Function ThisIsDistributedInformationBaseNode(Val InfobaseNode) Export

	Return InfobaseNode.Metadata().DistributedInfobase;
	
EndFunction

// It returns the flag of the node belonging to the exchange plan of the standard exchange (without conversion rules).
// 
// Parameters:
//  InfobaseNode - ExchangePlanRef - exchange plan node for which it is necessary to receive the funcion value.
// 
//  Returns:
//   True - the node belongs to the exchange plan of the standard exchange, otherwise False.
//
Function IsStandardDataExchangeNode(InfobaseNode) Export
	If ThisIsExchangePlanXDTO(InfobaseNode) Then
		Return False;
	EndIf;
	
	Return Not ThisIsDistributedInformationBaseNode(InfobaseNode)
		AND Not IsTemplateOfExchangePlan(GetExchangePlanName(InfobaseNode), "ExchangeRules");
	
EndFunction

// It returns the flag of the node belonging to the exchange plan of the universal exchange (based on conversion rules).
// 
// Parameters:
//  InfobaseNode - ExchangePlanRef - exchange plan node for which it is necessary to receive the funcion value.
// 
//  Returns:
//   True - the node belongs to the exchange plan of the universal exchange, otherwise False.
//
Function IsUniversalDataExchangeNode(InfobaseNode) Export
	
	If ThisIsExchangePlanXDTO(InfobaseNode) Then
		Return True;
	Else
		Return Not ThisIsDistributedInformationBaseNode(InfobaseNode)
			AND IsTemplateOfExchangePlan(GetExchangePlanName(InfobaseNode), "ExchangeRules");
	EndIf;
	//
EndFunction

// It returns the flag of the node belonging to the exchange plan that uses SSL exchange functionality.
// 
// Parameters:
//  InfobaseNode - ExchangePlanRef, ExchangePlanObject - exchange plan node for which
//                 it is necessary to receive the funcion value.
// 
//  Returns:
//   True - the node belongs to the exchange plan that uses BSP functionality, otherwise False.
//
Function IsSLDataExchangeNode(Val InfobaseNode) Export
	
	Return SSLExchangePlans().Find(GetExchangePlanName(InfobaseNode)) <> Undefined;
	
EndFunction

// It returns the flag of the node belonging to the separated exchange plan that uses SSL exchange functionality.
// 
// Parameters:
//  InfobaseNode - ExchangePlanRef - exchange plan node for which it is necessary to receive the funcion value.
// 
//  Returns:
//   True - the node belongs to a separated exchange plan that uses SSL functionality, otherwise False.
//
Function IsSeparatedSLDataExchangeNode(InfobaseNode) Export
	
	Return SeparatedSSLExchangePlans().Find(GetExchangePlanName(InfobaseNode)) <> Undefined;
	
EndFunction

// It returns the flag of the exchange plan belonging to DIB exchange plan.
// 
// Parameters:
//  ExchangePlanName - String - exchange plan name as specified in the designer.
// 
//  Returns:
//   True - the exchange plan belongs to the DIB exchange plan, otherwise False.
//
Function ThisIsExchangePlanOfDistributedInformationBase(ExchangePlanName) Export
	
	Return Metadata.ExchangePlans[ExchangePlanName].DistributedInfobase;
	
EndFunction

// It receives the exchange plan name as a metadata object for the specified node.
// 
// Parameters:
//  ExchangePlanNode - ExchangePlanRef, ExchangePlanObject - exchange plan node.
// 
// Returns:
//  Name - String - exchange plan name as a metadata object.
//
Function GetExchangePlanName(ExchangePlanNode) Export
	
	Return ExchangePlanNode.Metadata().Name;
	
EndFunction

// It receives the array of all nodes for the specified exchange plan except for the predefined node.
// 
// Parameters:
//  ExchangePlanName - String - exchange plan name as specified in the designer.
// 
// Returns:
//  NodesArray - Array - array of all nodes for the specified exchange plan except for the predefined node.
//
Function GetExchangePlanNodesArray(ExchangePlanName) Export
	
	ThisNode = ExchangePlans[ExchangePlanName].ThisNode();
	
	QueryText = "
	|SELECT
	| ExchangePlan.Ref
	|FROM ExchangePlan." + ExchangePlanName + " AS
	|ExchangePlan
	|	WHERE ExchangePlan.Ref <> &ThisNode";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("ThisNode", ThisNode);
	
	Return Query.Execute().Unload().UnloadColumn("Ref");
	
EndFunction

// It receives the layout list for the standard exchange rules from the configuration for specified exchange plan;
// the list is filled with the names and synonyms of the rule layouts.
// 
// Parameters:
//  ExchangePlanName - String - exchange plan name as specified in the designer.
// 
// Returns:
//  ListOfRules - value list - layout list for the standard exchange rules.
//
Function GetTypicalExchangeRulesList(ExchangePlanName) Export
	
	Return GetTypicalRulesList(ExchangePlanName, "ExchangeRules");
	
EndFunction

// It receives the layout list for the standard recording rules from the exchange plan configuration;
// the list is filled with the names and synonyms of the rule layouts.
// 
// Parameters:
//  ExchangePlanName - String - exchange plan name as specified in the designer.
// 
// Returns:
//  ListOfRules - value list - layout list for the standard recording rules.
//
Function GetTypicalRegistrationRulesList(ExchangePlanName) Export
	
	Return GetTypicalRulesList(ExchangePlanName, "RegistrationRules");
	
EndFunction

// It receives the list of the exchange configuration plans using SSL functionality.
// The list is filled with the names and synonyms of the exchange plans.
// 
// Parameters:
//  No.
// 
// Returns:
//  ExchangePlanList - value list - the list of the configuration exchange plans.
//
Function SLExchangePlanList() Export
	
	// Return value of the function.
	ExchangePlanList = New ValueList;
	
	SubsystemExchangePlans = New Valuelist;
	
	DataExchangeOverridable.GetExchangePlans(SubsystemExchangePlans);
	
	For Each ExchangePlan IN SubsystemExchangePlans Do
		
		ExchangePlanList.Add(ExchangePlan.Value.Name, ExchangePlan.Presentation);
		
	EndDo;
	
	Return ExchangePlanList;
EndFunction

// It receives the name array of configuration separated exchange plans that use SSL functionality.
// If the configuration does not contain delimiters, all exchange plans are considered to be separated (applied).
// 
// Parameters:
//  No.
// 
// Returns:
// Array - the array of name items for the separated exchange plans.
//
Function SeparatedSSLExchangePlans() Export
	
	Result = New Array;
	
	For Each ExchangePlanName IN SSLExchangePlans() Do
		
		If CommonUseReUse.IsSeparatedConfiguration() Then
			
			If CommonUseReUse.IsSeparatedMetadataObject("ExchangePlan." + ExchangePlanName,
					CommonUseReUse.MainDataSeparator()) Then
				
				Result.Add(ExchangePlanName);
				
			EndIf;
			
		Else
			
			Result.Add(ExchangePlanName);
			
		EndIf;
		
	EndDo;
	
	Return Result;
EndFunction

// For an internal use.
//
Function CommonNodeData(Val InfobaseNode) Export
	
	Return DataExchangeServer.CommonNodeData(GetExchangePlanName(InfobaseNode),
		InformationRegisters.InfobasesNodesCommonSettings.CorrespondentVersion(InfobaseNode)
	);
EndFunction

// For an internal use.
//
Function ExchangePlanTabularSections(Val ExchangePlanName, Val CorrespondentVersion = "") Export
	
	CommonTables             = New Array;
	ThisInfobaseTables          = New Array;
	CorrespondentTables    = New Array;
	AllInfobaseTables       = New Array;
	AllCorrespondentTables = New Array;
	
	CommonNodeData = DataExchangeServer.CommonNodeData(ExchangePlanName, CorrespondentVersion);
	
	TabularSections = DataExchangeEvents.ObjectTabularSections(Metadata.ExchangePlans[ExchangePlanName]);
	
	If Not IsBlankString(CommonNodeData) Then
		
		For Each TabularSection IN TabularSections Do
			
			If Find(CommonNodeData, TabularSection) <> 0 Then
				
				CommonTables.Add(TabularSection);
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	ThisInfobaseSettings = DataExchangeServer.FilterSsettingsAtNode(ExchangePlanName, CorrespondentVersion);
	
	ThisInfobaseSettings = DataExchangeEvents.StructureKeysToString(ThisInfobaseSettings);
	
	If IsBlankString(CommonNodeData) Then
		
		For Each TabularSection IN TabularSections Do
			
			If Find(ThisInfobaseSettings, TabularSection) <> 0 Then
				
				ThisInfobaseTables.Add(TabularSection);
				
				AllInfobaseTables.Add(TabularSection);
				
			EndIf;
			
		EndDo;
		
	Else
		
		For Each TabularSection IN TabularSections Do
			
			If Find(ThisInfobaseSettings, TabularSection) <> 0 Then
				
				AllInfobaseTables.Add(TabularSection);
				
				If Find(CommonNodeData, TabularSection) = 0 Then
					
					ThisInfobaseTables.Add(TabularSection);
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	CorrespondentSettings = DataExchangeServer.CorrespondentInfobaseNodeFilterSetup(ExchangePlanName, CorrespondentVersion);
	
	If IsBlankString(CommonNodeData) Then
		
		For Each CorrespondentSetting IN CorrespondentSettings Do
			
			If TypeOf(CorrespondentSetting.Value) = Type("Structure") Then
				
				CorrespondentTables.Add(CorrespondentSetting.Key);
				
				AllCorrespondentTables.Add(CorrespondentSetting.Key);
				
			EndIf;
			
		EndDo;
		
	Else
		
		For Each CorrespondentSetting IN CorrespondentSettings Do
			
			If TypeOf(CorrespondentSetting.Value) = Type("Structure") Then
				
				AllCorrespondentTables.Add(CorrespondentSetting.Key);
				
				If Find(CommonNodeData, CorrespondentSetting.Key) = 0 Then
					
					CorrespondentTables.Add(CorrespondentSetting.Key);
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Result = New Structure;
	Result.Insert("CommonTables",             CommonTables);
	Result.Insert("ThisInfobaseTables",          ThisInfobaseTables);
	Result.Insert("CorrespondentTables",    CorrespondentTables);
	Result.Insert("AllInfobaseTables",       AllInfobaseTables);
	Result.Insert("AllCorrespondentTables", AllCorrespondentTables);
	
	Return Result;
EndFunction

// The exchange plan manager receives using exchange plan name.
//
// Parameters:
//  ExchangePlanName - String - exchange plan name as specified in the designer.
//
// Returns:
//  ExchangePlanManager - exchange plan manager.
//
Function GetExchangePlanManagerByName(ExchangePlanName) Export
	
	Return ExchangePlans[ExchangePlanName];
	
EndFunction

// The exchange plan manager receives it by the metadata object name of the exchange plan.
//
// Parameters:
//  ExchangePlanNode - ExchangePlanRef - exchange plan node for which the manager shall be received.
// 
Function GetExchangePlanManager(ExchangePlanNode) Export
	
	Return GetExchangePlanManagerByName(GetExchangePlanName(ExchangePlanNode));
	
EndFunction

// Wrapper function for the cognominal function.
//
Function GetConfigurationMetadataTree(Filter) Export
	
	For Each FilterItem IN Filter Do
		
		Filter[FilterItem.Key] = StringFunctionsClientServer.DecomposeStringIntoSubstringsArray(FilterItem.Value);
		
	EndDo;
	
	Return CommonUse.GetConfigurationMetadataTree(Filter);
	
EndFunction

// Wrapper function for the cognominal function of DataExchangeServer module.
//
Function DataProcessorForDataImport(Cancel, Val InfobaseNode, Val ExchangeMessageFileName) Export
	
	Return DataExchangeServer.DataProcessorForDataImport(Cancel, InfobaseNode, ExchangeMessageFileName);
	
EndFunction

// It defines the layout availability for the exchange plan.
// 
// Parameters:
//  ExchangePlanName - String - exchange plan name as specified in the designer.
//  TemplateName - String - layout name which existence shall be defined.
// 
//  Returns:
//   True - The exchange plan contains the specified layout, otherwise False.
//
Function IsTemplateOfExchangePlan(Val ExchangePlanName, Val TemplateName) Export
	
	Return Metadata.ExchangePlans[ExchangePlanName].Templates.Find(TemplateName) <> Undefined;
	
EndFunction

// Wrapper function for the cognominal function of DataExchangeEvents module.
//
Function NodesArrayByPropertiesValues(PropertyValues, QueryText, ExchangePlanName, FlagAttributeName, Val Exporting = False) Export
	
	#If ExternalConnection OR ThickClientOrdinaryApplication Then
		
		Return DataExchangeServerCall.NodesArrayByPropertiesValues(PropertyValues, QueryText, ExchangePlanName, FlagAttributeName, Exporting);
		
	#Else
		
		SetPrivilegedMode(True);
		Return DataExchangeEvents.NodesArrayByPropertiesValues(PropertyValues, QueryText, ExchangePlanName, FlagAttributeName, Exporting);
		
	#EndIf
	
EndFunction

// It returns the collection of the exchange message transports used for the specified exchange plan node.
// 
// Parameters:
//  InfobaseNode - ExchangePlanRef - exchange plan node for which it is necessary to receive the funcion value.
// 
//  Returns:
//   Array - Used exchange message vehicles for the node.
//
Function UsedTransportsOfExchangeMessages(InfobaseNode) Export
	
	Result = ExchangePlans[GetExchangePlanName(InfobaseNode)].UsedTransportsOfExchangeMessages();
	
	// For the basic configuration versions the exchange using COM connection and Web service is not supported.
	If StandardSubsystemsServer.ThisIsBasicConfigurationVersion() Then
		
		CommonUseClientServer.DeleteValueFromArray(Result, Enums.ExchangeMessagesTransportKinds.COM);
		CommonUseClientServer.DeleteValueFromArray(Result, Enums.ExchangeMessagesTransportKinds.WS);
		
	EndIf;
		
	// Do not support the exchange using COM connection for DIB exchange.
	If ThisIsDistributedInformationBaseNode(InfobaseNode) Then
		
		CommonUseClientServer.DeleteValueFromArray(Result, Enums.ExchangeMessagesTransportKinds.COM);
		
		If Not ThisIsNodeOfOfflineWorkplace(InfobaseNode) Then
			CommonUseClientServer.DeleteValueFromArray(Result, Enums.ExchangeMessagesTransportKinds.WS);
		EndIf;
		
	EndIf;
	
	// For the standard exchange (without conversion rules usage) do not support an exchange using COM connection.
	If IsStandardDataExchangeNode(InfobaseNode) Then
		
		CommonUseClientServer.DeleteValueFromArray(Result, Enums.ExchangeMessagesTransportKinds.COM);
		
	EndIf;
	
	// If 1C server is running on the Linux OS, exchange using COM connection is not supported.
	If CommonUse.ThisLinuxServer() Then
		
		CommonUseClientServer.DeleteValueFromArray(Result, Enums.ExchangeMessagesTransportKinds.COM);
		
	EndIf;
	
	Return Result;
EndFunction

// It sets the external connection with the infobase and returns a pointer to this connection.
// 
// Parameters:
//  InfobaseNode (mandatory) - ExchangePlanRef. Exchange plan node for which
//  it is nesessary to set external connection.
//  ErrorMessageString (optional) - String - if an error occurs while establishing external
// connection, then the error detailed description is put to this parameter.
//
// Returns:
//  COM-object - in case of successful external connection, in case of error Undefined is returned.
//
Function GetExternalConnectionForInfobaseNode(InfobaseNode, ErrorMessageString = "") Export

	Result = OuterJoinForAnInformationBaseNode(InfobaseNode);

	ErrorMessageString = Result.DetailedErrorDescription;
	Return Result.Join;
	
EndFunction

// It sets the external connection with the infobase and returns a pointer to this connection.
// 
// Parameters:
//  InfobaseNode (mandatory) - ExchangePlanRef. Exchange plan node for which
//  it is nesessary to set external connection.
//  ErrorMessageString (optional) - String - if an error occurs while establishing external
//  connection, then the error detailed description is put to this parameter.
//
// Returns:
//  COM-object - in case of successful external connection, in case of error Undefined is returned.
//
Function OuterJoinForAnInformationBaseNode(InfobaseNode) Export
	
	Return DataExchangeServer.InstallOuterDatabaseJoin(
        InformationRegisters.ExchangeTransportSettings.TransportSettings(
            InfobaseNode, Enums.ExchangeMessagesTransportKinds.COM));
	
EndFunction

// Defines if it is possible to pass files from one base to another via the local area network.
//
// Parameters:
//  InfobaseNode   - ExchangePlanRef - node of the exchange plan for which
//                                     the exchange message is received.
//  Password       - String - Password for WS connection.
//
Function IsExchangeInSameLAN(Val InfobaseNode, Val AuthenticationParameters = Undefined) Export
	
	Return DataExchangeServer.IsExchangeInSameLAN(InfobaseNode, AuthenticationParameters);
	
EndFunction

// It returns the flag of the exchange plan accessibility.
// The flag is calculated based on the composition of all functional configuration options.
// If the exchange plan is not included in any functional option, then True is returned.
// If the exchange plan is included in the functional options, then True is returned if
// at least one functional option is enabled.
// Otherwise the function returns False.
//
// Parameters:
//  ExchangePlanName - String. Exchange plan name for which it is necessary to compute the usage flag.
//
// Returns:
//  True  - exchange plan is available.
//  False - usage is not available.
//
Function CanUseExchangePlan(Val ExchangePlanName) Export
	
	ObjectIsInFunctionalOptionContent = False;
	
	For Each FunctionalOption IN Metadata.FunctionalOptions Do
		
		If FunctionalOption.Content.Contains(Metadata.ExchangePlans[ExchangePlanName]) Then
			
			ObjectIsInFunctionalOptionContent = True;
			
			If GetFunctionalOption(FunctionalOption.Name) = True Then
				
				Return True;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If Not ObjectIsInFunctionalOptionContent Then
		
		Return True;
		
	EndIf;
	
	Return False;
EndFunction

// Returns array of the versions numbers supported by the correspondent interface for the DataExchange subsystem.
// 
// Parameters:
// Correspondent - Structure, ExchangePlanRef. Exchange plan node that
//                 corresponds to the correspondent infobase.
//
// Returns:
// Array of the version numbers supported by the correspondent interface.
//
Function CorrespondentVersions(Val Correspondent) Export
	
	If TypeOf(Correspondent) = Type("Structure") Then
		SettingsStructure = Correspondent;
	Else
		SettingsStructure = InformationRegisters.ExchangeTransportSettings.TransportSettingsWS(Correspondent);
	EndIf;
	
	ConnectionParameters = New Structure;
	ConnectionParameters.Insert("URL",      SettingsStructure.WSURLWebService);
	ConnectionParameters.Insert("UserName", SettingsStructure.WSUserName);
	ConnectionParameters.Insert("Password", SettingsStructure.WSPassword);
	
	Return CommonUse.GetInterfaceVersions(ConnectionParameters, "DataExchange");
EndFunction

// It returns the array of all reference types specified in the configuration.
//
Function AllConfigurationReferenceTypes() Export
	
	Result = New Array;
	
	CommonUseClientServer.SupplementArray(Result, Catalogs.AllRefsType().Types());
	CommonUseClientServer.SupplementArray(Result, Documents.AllRefsType().Types());
	CommonUseClientServer.SupplementArray(Result, BusinessProcesses.AllRefsType().Types());
	CommonUseClientServer.SupplementArray(Result, ChartsOfCharacteristicTypes.AllRefsType().Types());
	CommonUseClientServer.SupplementArray(Result, ChartsOfAccounts.AllRefsType().Types());
	CommonUseClientServer.SupplementArray(Result, ChartsOfCalculationTypes.AllRefsType().Types());
	CommonUseClientServer.SupplementArray(Result, Tasks.AllRefsType().Types());
	CommonUseClientServer.SupplementArray(Result, ExchangePlans.AllRefsType().Types());
	CommonUseClientServer.SupplementArray(Result, Enums.AllRefsType().Types());
	
	Return Result;
EndFunction

Function OfflineWorkExchangePlans()
	
	// The exchange plan to arrange offline work in the service model shall:
	// - be separated
	// - be the exchange plan of the distributed IB
	// - used for the exchange in the service model (ExchangePlanUsedSaaS = True).
	
	Result = New Array;
	
	For Each ExchangePlan IN Metadata.ExchangePlans Do
		
		If DataExchangeServer.IsSeparatedExchangePlanSSL(ExchangePlan.Name)
			AND ExchangePlan.DistributedInfobase
			AND ExchangePlanUsedSaaS(ExchangePlan.Name) Then
			
			Result.Add(ExchangePlan.Name);
			
		EndIf;
		
	EndDo;
	
	Return Result;
EndFunction

Function SecurityProfileName(Val ExchangePlanName) Export
	
	If Catalogs.MetadataObjectIDs.DataUpdated() Then
		ExchangePlanID = CommonUse.MetadataObjectID(Metadata.ExchangePlans[ExchangePlanName]);
		SecurityProfileName = WorkInSafeModeService.ExternalModuleConnectionMode(ExchangePlanID);
	Else
		SecurityProfileName = Undefined;
	EndIf;
	
	If SecurityProfileName = Undefined Then
		SecurityProfileName = Constants.InfobaseSecurityProfile.Get();
		If IsBlankString(SecurityProfileName) Then
			SecurityProfileName = Undefined;
		EndIf;
	EndIf;
	
	Return SecurityProfileName;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Initialization of the data exchange settings structure.

// Initializes the subsystem of data exchange to execute the exchange process.
// 
// Parameters:
// 
// Returns:
//  ExchangeSettingsStructure - Structure - structure with all necessary data and objects for exchange.
//
Function GetExchangeSettingsStructureForInfobaseNode(
	InfobaseNode,
	ActionOnExchange,
	ExchangeMessageTransportKind,
	UseTransportSettings = True
	) Export
	
	Return DataExchangeServer.GetExchangeSettingsStructureForInfobaseNode(
		InfobaseNode,
		ActionOnExchange,
		ExchangeMessageTransportKind,
		UseTransportSettings);
EndFunction

// Initializes the subsystem of data exchange to execute the exchange process.
// 
// Parameters:
// 
// Returns:
//  ExchangeSettingsStructure - Structure - structure with all necessary data and objects for exchange.
//
Function GetExchangeSettingsStructure(ExchangeExecutionSettings, LineNumber) Export
	
	Return DataExchangeServer.GetExchangeSettingsStructure(ExchangeExecutionSettings, LineNumber);
	
EndFunction

// It receives the vehicle setting structure for the data exchange.
//
Function GetSettingsStructureOfTransport(InfobaseNode, ExchangeMessageTransportKind) Export
	
	Return DataExchangeServer.GetSettingsStructureOfTransport(InfobaseNode, ExchangeMessageTransportKind);
	
EndFunction

// It receives the layout list of the standard data exchange rules from the configuration for the specified exchange plan;
// the list is filled with the names and synonyms of the rule layouts.
// 
// Parameters:
//  ExchangePlanName - String - exchange plan name as specified in the designer.
// 
// Returns:
//  ListOfRules - value list - layout list of the standard data exchange rules.
//
Function GetTypicalRulesList(ExchangePlanName, TemplateNameLiteral)
	
	ListOfRules = New ValueList;
	
	If IsBlankString(ExchangePlanName) Then
		Return ListOfRules;
	EndIf;
	
	For Each Template IN Metadata.ExchangePlans[ExchangePlanName].Templates Do
		
		If Find(Template.Name, TemplateNameLiteral) <> 0 AND Find(Template.Name, "correspondent") = 0 Then
			
			ListOfRules.Add(Template.Name, Template.Synonym);
			
		EndIf;
		
	EndDo;
	
	Return ListOfRules;
EndFunction

// It returns the node content table (only reference types).
//
// Parameters:
//    ExchangePlanName - String - analyzed exchange plan.
//    Periodic         - flag showing that it is necessary to include objects with the date (documents, etc.) to the result.
//    Reference        - flag showing that normative reference objects shall be included in the result.
//
// Returns:
//    ValueTable   - table with columns:
//      * MetadataFullName - String - Metadata full name (table name for query).
//      * ListPresentation - String - list presentation for the table.
//      * Presentation     - String - object presentation for the table.
//      * PictureIndex     - Number - image index according to ImageLibrary.CollectionMetadataObjects.
//      * Type             - Type - corresponding type.
//      * PeriodSelection  - Boolean - the flag showing that you can use the period filter to the object.
//
Function ExchangePlanContent(ExchangePlanName, Periodic = True, Reference = True) Export
	
	ResultTable = New ValueTable;
	For Each KeyValue IN (New Structure("FullMetadataName, Presentation, ListPresentation, ImageIndex, Type, PeriodSelection")) Do
		ResultTable.Columns.Add(KeyValue.Key);
	EndDo;
	For Each KeyValue IN (New Structure("FullMetadataName, Presentation, ListPresentation, Type")) Do
		ResultTable.Indexes.Add(KeyValue.Key);
	EndDo;
	
	ExchangePlanContent = Metadata.ExchangePlans.Find(ExchangePlanName).Content;
	For Each ContentItem IN ExchangePlanContent Do
		
		ObjectMetadata = ContentItem.Metadata;
		Definition = MetadataObjectDesc(ObjectMetadata);
		If Definition.PictureIndex >= 0 Then
			If Not Periodic AND Definition.Periodical Then 
				Continue;
			ElsIf Not Reference AND Definition.Help Then 
				Continue;
			EndIf;
			
			String = ResultTable.Add();
			FillPropertyValues(String, Definition);
			String.PeriodSelection        = Definition.Periodical;
			String.FullMetadataName = ObjectMetadata.FullName();
			String.ListPresentation = DataExchangeServer.SubmissionOfObjectsList(ObjectMetadata);
			String.Presentation       = DataExchangeServer.ObjectPresentation(ObjectMetadata);
		EndIf;
	EndDo;
	
	ResultTable.Sort("ListPresentation");
	Return ResultTable;
	
EndFunction

Function MetadataObjectDesc(Meta)
	
	Result = New Structure("PictureIndex, Periodical, Help, Type", -1, False, False);
	
	If Metadata.Catalogs.Contains(Meta) Then
		Result.PictureIndex = 3;
		Result.Help = True;
		Result.Type = Type("CatalogRef." + Meta.Name);
		
	ElsIf Metadata.Documents.Contains(Meta) Then
		Result.PictureIndex = 7;
		Result.Periodical = True;
		Result.Type = Type("DocumentRef." + Meta.Name);
		
	ElsIf Metadata.ChartsOfCharacteristicTypes.Contains(Meta) Then
		Result.PictureIndex = 9;
		Result.Help = True;
		Result.Type = Type("ChartOfCharacteristicTypesRef." + Meta.Name);
		
	ElsIf Metadata.ChartsOfAccounts.Contains(Meta) Then
		Result.PictureIndex = 11;
		Result.Help = True;
		Result.Type = Type("ChartOfAccountsRef." + Meta.Name);
		
	ElsIf Metadata.ChartsOfCalculationTypes.Contains(Meta) Then
		Result.PictureIndex = 13;
		Result.Help = True;
		Result.Type = Type("ChartOfCalculationTypesRef." + Meta.Name);
		
	ElsIf Metadata.BusinessProcesses.Contains(Meta) Then
		Result.PictureIndex = 23;
		Result.Periodical = True;
		Result.Type = Type("BusinessProcessRef." + Meta.Name);
		
	ElsIf Metadata.Tasks.Contains(Meta) Then
		Result.PictureIndex = 25;
		Result.Periodical  = True;
		Result.Type = Type("TaskRef." + Meta.Name);
		
	EndIf;
	
	Return Result;
EndFunction

// It specifies whether the versioning is used.
//
// Parameters:
// Sender - ExchangePlanRef - If the parameter is transferred,
// 	then it determines whether it is necessary to create object versions for the transferred node.
//
Function UseVersioning(Sender = Undefined, CheckAccessRights = False) Export
	
	Used = False;
	
	If CommonUse.SubsystemExists("StandardSubsystems.ObjectVersioning") Then
		
		Used = ?(Sender <> Undefined, IsSLDataExchangeNode(Sender), True);
		
		If Used AND CheckAccessRights Then
			
			ObjectVersioningModule = CommonUse.CommonModule("ObjectVersioning");
			Used = ObjectVersioningModule.HasRightToReadVersions();
			
		EndIf;
			
	EndIf;
	
	Return Used;
	
EndFunction

// The function returns the name of the temporary file directory.
//
// Returns:
// String - path to the temporary file folder.
//
Function TempFileStorageDirectory() Export
	
	// If it is the file base, then TempFilesDirectory is returned.
	If CommonUse.FileInfobase() Then 
		Return TrimAll(TempFilesDir());
	EndIf;
	
	CommonPlatformType = "Windows";
	
	ServerPlatformType = CommonUseReUse.ServerPlatformType();
	
	SetPrivilegedMode(True);
	
	If    ServerPlatformType = PlatformType.Windows_x86
		OR ServerPlatformType = PlatformType.Windows_x86_64 Then
		
		Result         = Constants.DataExchangeMessagesDirectoryForWindows.Get();
		
	ElsIf ServerPlatformType = PlatformType.Linux_x86
		OR   ServerPlatformType = PlatformType.Linux_x86_64 Then
		
		Result         = Constants.DataExchangeMessagesDirectoryForLinux.Get();
		CommonPlatformType = "Linux";
		
	Else
		
		Result         = Constants.DataExchangeMessagesDirectoryForWindows.Get();
		
	EndIf;
	
	SetPrivilegedMode(False);
	
	ConstantRepresentation = ?(CommonPlatformType = "Linux", 
		Metadata.Constants.DataExchangeMessagesDirectoryForLinux.Presentation(),
		Metadata.Constants.DataExchangeMessagesDirectoryForWindows.Presentation());
	
	If IsBlankString(Result) Then
		
		Result = TrimAll(TempFilesDir());
		
	Else
		
		Result = TrimAll(Result);
		
		// Directory existence check.
		Directory = New File(Result);
		If Not Directory.Exist() Then
			
			MessagePattern = NStr("en='Temporary file directory does not exist."
"It is necessary to make sure that the right"
"parameter value %1 is specified in the application settings.';ru='Каталог временных файлов не существует."
"Необходимо убедиться, что в настройках"
"программы задано правильное значение параметра ""%1"".';vi='Không tồn tại thư mục của tệp tạm thời."
"Cần chắc chắn rằng, trong tùy chỉnh"
"chương trình đã đặt đúng giá trị tham số ""%1"".'");
			MessageText = StringFunctionsClientServer.SubstituteParametersInString(MessagePattern, ConstantRepresentation);
			Raise(MessageText);
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function ParametersMap() Export
	
	Result = New Map;
	
	Result.Insert("UUID", "УникальныйИдентификатор");
	Result.Insert("Rows", "Строки");
	Result.Insert("ObjectDeletion", "УдалениеОбъекта");
	Result.Insert("RecordSetRows", "СтрокиНабораЗаписей");
	Result.Insert("InformationRegisterRecordSet" ,"РегистрСведенийНаборЗаписей");
	Result.Insert("Filter", "Отбор");
	Result.Insert("RegisterRecordSet", "НаборЗаписейРегистра");
	Result.Insert("ObjectChangeRecordData", "ИнформацияОРегистрацииОбъекта");
	Result.Insert("UniqueSourceHandle", "УникальныйИдентификаторИсточника");
	Result.Insert("UniqueReceiverHandle", "УникальныйИдентификаторПриемника");
	Result.Insert("SourceType", "ТипИсточника");
	Result.Insert("ReceiverType", "ТипПриемника");
	Result.Insert("EmptySet", "ПустойНабор");
	
	Result.Insert("Code", "Код");
	Result.Insert("Date", "Дата");
	Result.Insert("Number", "Номер");

	Result.Insert("TabularSection", "ТабличнаяЧасть");
	Result.Insert("DataClearingRules", "ПравилаОчисткиДанных");
	Result.Insert("ExchangeCompanyManagementAccounting", "ОбменУправлениеНебольшойФирмойБухгалтерия");
	Result.Insert("CommonNodeData", "ОбщиеДанныеУзлов");
	Result.Insert("SenderVersion", "ВерсияОтправителя");
	Result.Insert("DeleteChangeRecords", "УдалитьРегистрациюИзменений");
	Result.Insert("IncomingMessageNumber", "НомерВходящегоСообщения");
	Result.Insert("OutboundMessageNumber", "НомерИсходящегоСообщения");
	Result.Insert("FromWhom", "ОтКого");
	Result.Insert("Whom", "Кому");
	Result.Insert("ExchangePlan", "ПланОбмена");
	Result.Insert("ExchangeData", "ДанныеПоОбмену");
	Result.Insert("SentNo","НомерОтправленного");
	Result.Insert("AfterParameterExportAlgorithm", "АлгоритмПослеЗагрузкиПараметров");
	Result.Insert("AfterParametersImport", "ПослеЗагрузкиПараметров");
	Result.Insert("DataProcessor", "Обработка");
	Result.Insert("DataProcessors", "Обработки");
	Result.Insert("Parameter", "Параметр");
	Result.Insert("Parameters", "Параметры");
	Result.Insert("CreationDateTime", "ДатаВремяСоздания");
	Result.Insert("Description", "Наименование");
	Result.Insert("ID", "ИД");
	Result.Insert("Receiver", "Приемник");
	Result.Insert("Source", "Источник");
	
	Result.Insert("ExchangeRules", "ФайлОбмена");
	
	Result.Insert("ExchangeFile", "ФайлОбмена");
	Result.Insert("FormatVersion", "ВерсияФормата");
	Result.Insert("ExportDate", "ДатаВыгрузки");
	
	Result.Insert("SourceConfigurationName", "ИмяКонфигурацииИсточника");
	Result.Insert("SourceConfigurationVersion", "ВерсияКонфигурацииИсточника");
	Result.Insert("TargetConfigurationName", "ИмяКонфигурацииПриемника");
	Result.Insert("ConversionRuleIDs", "ИдПравилКонвертации");
	//Result.Insert("TargetConfigurationName", "ИмяКонфигурацииПриемника");
	
	Result.Insert("ExtDimensionСr", "СубконтоКт");
	Result.Insert("ExtDimensionDr", "СубконтоДт");
	Result.Insert("Record", "Запись");
	Result.Insert("Expression", "Выражение");
	Result.Insert("Value", "Значение");
	Result.Insert("SearchByEqualDate", "ПоискПоДатеНаРавенство");
	Result.Insert("{TypeNameInIBReceiver}","{ИмяТипаВИБПриемнике}");
	Result.Insert("{TypeNameInIBSource}","{ИмяТипаВИБИсточнике}");
	Result.Insert("{SearchKeyInIBReceiver}", "{КлючПоискаВИБПриемнике}");
	Result.Insert("{SearchKeyInIBSource}", "{КлючПоискаВИБИсточнике}");
	Result.Insert("{PredefinedItemName}","{ИмяПредопределенногоЭлемента}");
	Result.Insert("{UUID}", "{УникальныйИдентификатор}");
	Result.Insert("SourceType", "ТипИсточника");
	Result.Insert("ReceiverType", "ТипПриемника");
	Result.Insert("Task", "Задача");
	Result.Insert("BusinessProcess", "БизнесПроцесс");
	Result.Insert("ContinueSearch", "ПродолжитьПоиск");
	Result.Insert("DontReplaceCreatedInTargetObject", "НеЗамещатьОбъектСозданныйВИнформационнойБазеПриемнике");
	Result.Insert("RecordObjectChangeAtSenderNode", "РегистрироватьОбъектНаУзлеОтправителе");
	Result.Insert("DoNotCreateIfNotFound", "НеСоздаватьЕслиНеНайден");
	Result.Insert("Type", "Тип");
	Result.Insert("NPP", "Нпп");
	Result.Insert("GSn", "ГНпп");
	Result.Insert("Rulename", "ИмяПравила");
	Result.Insert("Donotreplace", "НеЗамещать");
	Result.Insert("AutonumerationPrefix", "ПрефиксАвтонумерации");
	Result.Insert("Document", "Документ");
	Result.Insert("WriteMode", "РежимЗаписи");
	Result.Insert("PostingMode", "РежимПроведения");
	Result.Insert("Object", "Объект");
	Result.Insert("Property", "Свойство");
	Result.Insert("ParameterValue", "ЗначениеПараметра");
	Result.Insert("Constants", "Константы");
	Result.Insert("Name", "Имя");
	Result.Insert("OCRName", "ИмяПКО");
	Result.Insert("IsFolder", "ЭтоГруппа");
	Result.Insert("Ref", "Ссылка");
	Result.Insert("Enum", "Перечисление");
	Result.Insert("TabularSection", "ТабличнаяЧасть");
	Result.Insert("RecordSet", "НаборЗаписей");
	Result.Insert("ExchangePlan", "ПланОбмена");
	Result.Insert("Donotclear", "НеОчищать");
	Result.Insert("Document", "Документ");
	Result.Insert("Posting", "Проведение");
	Result.Insert("UndoPosting", "ОтменаПроведения");
	Result.Insert("RealTime", "Оперативный");
	Result.Insert("InformationRegister", "InformationRegister");
	Result.Insert("Constants", "Константы");
	Result.Insert("SequenceRecordSet", "НаборЗаписейПоследовательности");
	Result.Insert("Types", "Типы");
	Result.Insert("CatalogRef", "СправочникСсылка");
	Result.Insert("DocumentRef", "ДокументСсылка");
	
	Return Result;
	
EndFunction


#EndRegion
