///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2020, ООО 1С-Софт
// Все права защищены. Эта программа и сопроводительные материалы предоставляются 
// в соответствии с условиями лицензии Attribution 4.0 International (CC BY 4.0)
// Текст лицензии доступен по ссылке:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region ServiceProgramInterface

#Region RunExternalApplications

Function SafeCommandString(StartupCommand) Export
	
	Result = "";
	
	If TypeOf(StartupCommand) = Type("String") Then 
		
		If ContainsUnsafeActions(StartupCommand) Then 
			Raise StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en='Не удалось запустить программу"
"по причине:"
"Недопустимая строка команды"
"%1"
"по причине:"
"Строка команды не должна содержать символы: ""$"", ""`"", ""|"", "";"", ""&"".';ru='Не удалось запустить программу"
"по причине:"
"Недопустимая строка команды"
"%1"
"по причине:"
"Строка команды не должна содержать символы: ""$"", ""`"", ""|"", "";"", ""&"".';vi='Chương trình không khởi động được"
"vì:"
"Dòng lệnh không hợp lệ"
"%1 "
"vì:"
"Dòng lệnh không được chứa các ký tự: ""$"", ""` "","" | "",""; "","" & "".'"),
				StartupCommand);
		EndIf;
		
		Result = StartupCommand;
		
	ElsIf TypeOf(StartupCommand) = Type("Array") Then
		
		If StartupCommand.Count() > 0 Then 
			
			If ContainsUnsafeActions(StartupCommand[0]) Then
				Raise StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en='Не удалось запустить программу"
"по причине:"
"Недопустимая команда или путь к исполняемому файлу"
"%1"
"по причине:"
"Команда не должна содержать символы: ""$"", ""`"", ""|"", "";"", ""&"".';ru='Не удалось запустить программу"
"по причине:"
"Недопустимая команда или путь к исполняемому файлу"
"%1"
"по причине:"
"Команда не должна содержать символы: ""$"", ""`"", ""|"", "";"", ""&"".';vi='Không thể khởi chạy chương trình"
"do:"
"Lệnh hoặc đường dẫn không hợp lệ đến tệp thực thi"
"%1"
"vì lý do:"
"Lệnh không được chứa các ký tự: ""$"", ""` "","" | "",""; "","" & "".'"),
				StartupCommand[0]);
			EndIf;
			
			Result = ArrayToCommandString(StartupCommand);
			
		Else
			Raise
				NStr("en='Ожидалось, что первый элемент массива КомандаЗапуска будет командой или путем к исполняемому файлу.';ru='Ожидалось, что первый элемент массива КомандаЗапуска будет командой или путем к исполняемому файлу.';vi='Phần tử đầu tiên của mảng RunCommand được mong đợi là một lệnh hoặc đường dẫn đến một tệp thực thi.'");
		EndIf;
		
	Else 
		Raise 
			NStr("en='Ожидалось, что значение КомандаЗапуска будет <Строка> или <Массив>';ru='Ожидалось, что значение КомандаЗапуска будет <Строка> или <Массив>';vi='Giá trị RunCommand được mong đợi là <Chuỗi> hoặc <Dải>'");
	EndIf;
		
	Return Result
	
EndFunction

#EndRegion

#Region SpreadsheetDocument

////////////////////////////////////////////////////////////////////////////////
// Функции для работы с табличными документами.

// Calculates the numeric cell indicators in the spreadsheet document.
//
// Parameters:
//   SpreadsheetDocument - SpreadsheetDocument - ТабличныйДокумент, показатели которого рассчитываются.
//   SelectedAreas - CommonInternalClient.CellsIndicatorsCalculationParameters. See также
//
// Returns:
//   Structure - Results selected cell calculation.
//       * Количество         - Число - Количество выделенных ячеек.
//       * КоличествоЧисловых - Число - Количество числовых ячеек.
//       * Сумма      - Число - Сумма выделенных ячеек с числами.
//       * Среднее    - Число - Сумма выделенных ячеек с числами.
//       * Минимум    - Число - Сумма выделенных ячеек с числами.
//       * Максимум   - Число - Максимум выделенных ячеек с числами.
//
Function CalculationCellsIndicators(Val SpreadsheetDocument, SelectedAreas) Export 
	
	#Region ResultConstructor
	
	CalculationIndicators = New Structure;
	CalculationIndicators.Insert("Quantity", 0);
	CalculationIndicators.Insert("FilledCellsQuantity", 0);
	CalculationIndicators.Insert("NumericCellsQuantity", 0);
	CalculationIndicators.Insert("Amount", 0);
	CalculationIndicators.Insert("AVG", 0);
	CalculationIndicators.Insert("Minimum", 0);
	CalculationIndicators.Insert("Maximum", 0);
	
	#EndRegion
	
	CheckedCells = New Map;
	
	For Each SelectedArea In SelectedAreas Do
		
		If TypeOf(SelectedArea) <> Type("SpreadsheetDocumentRange")
			And TypeOf(SelectedArea) <> Type("Structure") Then
			Continue;
		EndIf;
		
		#Region SelectedAreaBoundariesDetermination
		
		MarkedAreaTop  = SelectedArea.Top;
		SelectedAreaBottom   = SelectedArea.Bottom;
		MarkedAreaLeft  = SelectedArea.Left;
		MarkedAreaRight = SelectedArea.Right;
		
		If MarkedAreaTop = 0 Then
			MarkedAreaTop = 1;
		EndIf;
		
		If SelectedAreaBottom = 0 Then
			SelectedAreaBottom = SpreadsheetDocument.TableHeight;
		EndIf;
		
		If MarkedAreaLeft = 0 Then
			MarkedAreaLeft = 1;
		EndIf;
		
		If MarkedAreaRight = 0 Then
			MarkedAreaRight = SpreadsheetDocument.TableWidth;
		EndIf;
		
		If SelectedArea.AreaType = SpreadsheetDocumentCellAreaType.Columns Then
			MarkedAreaTop = SelectedArea.Bottom;
			SelectedAreaBottom = SpreadsheetDocument.TableHeight;
		EndIf;
		
		MarkedAreaHeight = SelectedAreaBottom   - MarkedAreaTop + 1;
		MarkedAreaWidth = MarkedAreaRight - MarkedAreaLeft + 1;
		
		#EndRegion
		
		CalculationIndicators.Quantity = CalculationIndicators.Quantity + MarkedAreaWidth * MarkedAreaHeight;
		
		For ColumnNumber = MarkedAreaLeft To MarkedAreaRight Do
			
			For LineNumber = MarkedAreaTop To SelectedAreaBottom Do
				
				Cell = SpreadsheetDocument.Area(LineNumber, ColumnNumber, LineNumber, ColumnNumber);
				
				If CheckedCells.Get(Cell.Name) = Undefined Then
					CheckedCells.Insert(Cell.Name, True);
				Else
					Continue;
				EndIf;
				
				If Cell.Visible = True Then
					
					#Region CellValueDetermination
					
					If Cell.AreaType <> SpreadsheetDocumentCellAreaType.Columns
						And Cell.ContainsValue And TypeOf(Cell.Value) = Type("Number") Then
						
						Number = Cell.Value;
						
					ElsIf ValueIsFilled(Cell.Text) Then
						
						TypeDescriptionNumber = New TypeDescription("Number");
						
						TextCell = StrReplace(Cell.Text, " ", "");
						
						If StrStartsWith(TextCell, "(")
							And StrEndsWith(TextCell, ")") Then 
							
							TextCell = StrReplace(TextCell, "(", "");
							TextCell = StrReplace(TextCell, ")", "");
							
							Number = TypeDescriptionNumber.AdjustValue(TextCell);
							If Number > 0 Then 
								Number = -Number;
							EndIf;
						Else
							Number = TypeDescriptionNumber.AdjustValue(TextCell);
						EndIf;
						
					Else
						Continue;
					EndIf;
					
					#EndRegion
					
					CalculationIndicators.FilledCellsQuantity = CalculationIndicators.FilledCellsQuantity + 1;
					
					#Region IndicatorsCalculation
					
					If TypeOf(Number) = Type("Number") Then
						
						CalculationIndicators.NumericCellsQuantity = CalculationIndicators.NumericCellsQuantity + 1;
						CalculationIndicators.Amount = CalculationIndicators.Amount + Number;
						
						If CalculationIndicators.NumericCellsQuantity = 1 Then
							CalculationIndicators.Minimum  = Number;
							CalculationIndicators.Maximum = Number;
						Else
							CalculationIndicators.Minimum  = Min(Number,  CalculationIndicators.Minimum);
							CalculationIndicators.Maximum = Max(Number, CalculationIndicators.Maximum);
						EndIf;
						
					EndIf;
					
					#EndRegion
					
				EndIf;
				
			EndDo;
			
		EndDo;
		
	EndDo;
	
	If CalculationIndicators.NumericCellsQuantity > 0 Then
		CalculationIndicators.AVG = CalculationIndicators.Amount / CalculationIndicators.NumericCellsQuantity;
	EndIf;
	
	Return CalculationIndicators;
	
EndFunction

#EndRegion

#EndRegion

#Region InternalProceduresAndFunctions

#Region UserNotification

Procedure MessageToUser(
		Val MessageToUserText,
		Val DataKey,
		Val Field,
		Val DataPath = "",
		cancel = False,
		IsObject = False) Export
	
	Message = New UserMessage;
	Message.Text = MessageToUserText;
	Message.Field = Field;
	
	If IsObject Then
		Message.SetData(DataKey);
	Else
		Message.DataKey = DataKey;
	EndIf;
	
	If Not IsBlankString(DataPath) Then
		Message.DataPath = DataPath;
	EndIf;
	
	Message.Message();
	
	cancel = True;
	
EndProcedure

#EndRegion

#Region InfobaseData

#Region PredefinedItem

Function UseStandardGettingPredefinedItemFunction(FullPredefinedName) Export
	
	// Используется стандартная функция платформы для получения:
	//  - пустых ссылок; 
	//  - значений перечислений;
	//  - точек маршрута бизнес-процессов.
	
	Return ".EMPTYREF" = Upper(Right(FullPredefinedName, 13))
		Or "ENUM." = Upper(Left(FullPredefinedName, 13))
		Or "BUSINESSPROCESS." = Upper(Left(FullPredefinedName, 14));
	
EndFunction

Function PredefinedItemNameByFields(FullPredefinedName) Export
	
	FullNameParts = StrSplit(FullPredefinedName, ".");
	If FullNameParts.Count() <> 3 Then 
		Raise PredefinedValueNotFoundErrorText(FullPredefinedName);
	EndIf;
	
	FullMetadataObjectName = Upper(FullNameParts[0] + "." + FullNameParts[1]);
	PredefinedName = FullNameParts[2];
	
	Result = New Structure;
	Result.Insert("FullMetadataObjectName", FullMetadataObjectName);
	Result.Insert("PredefinedName", PredefinedName);
	
	Return Result;
	
EndFunction

Function PredefinedItem(FullPredefinedName, PredefinedItemFields, PredefinedValues) Export
	
	// Если ошибка в имени метаданных.
	If PredefinedValues = Undefined Then 
		Raise PredefinedValueNotFoundErrorText(FullPredefinedName);
	EndIf;
	
	// Получение результата из кэша.
	Result = PredefinedValues.Get(PredefinedItemFields.PredefinedName);
	
	// Если предопределенного нет в метаданных.
	If Result = Undefined Then 
		Raise PredefinedValueNotFoundErrorText(FullPredefinedName);
	EndIf;
	
	// Если предопределенный есть в метаданных, но не создан в ИБ.
	If Result = Null Then 
		Return Undefined;
	EndIf;
	
	Return Result;
	
EndFunction

Function PredefinedValueNotFoundErrorText(FullPredefinedName) Export
	
	Return StringFunctionsClientServer.SubstituteParametersInString(
		NStr("en='Предопределенное значение ""%1"" не найдено.';ru='Предопределенное значение ""%1"" не найдено.';vi='Không tìm thấy giá trị xác định trước ""%1"".'"), FullPredefinedName);
	
EndFunction

#EndRegion

#EndRegion

#Region Dates

Function LocalDatePresentationWithOffset(LocalDate, Shift) Export
	
	OffsetPresentation = "Z";
	
	If Shift > 0 Then
		OffsetPresentation = "+";
	ElsIf Shift < 0 Then
		OffsetPresentation = "-";
		Shift = -Shift;
	EndIf;
	
	If Shift <> 0 Then
		OffsetPresentation = OffsetPresentation + Format('00010101' + Shift, "DF=HH:mm");
	EndIf;
	
	Return Format(LocalDate, "DF=yyyy-MM-ddTHH:mm:ss; DE=0001-01-01T00:00:00") + OffsetPresentation;
	
EndFunction

#EndRegion

#Region ExternalConnection

Function InstallOuterDatabaseJoin(Parameters, ConnectionUnavailable, ErrorShortInfo) Export
	
	Result = New Structure;
	Result.Insert("Connection");
	Result.Insert("ErrorShortInfo", "");
	Result.Insert("DetailedErrorDescription", "");
	Result.Insert("ErrorAttachingAddIn", False);
	
#If MobileClient Then
	
	ErrorMessageString = NStr("en='Подключение к другой программе не доступно в мобильном клиенте.';ru='Подключение к другой программе не доступно в мобильном клиенте.';vi='Kết nối với chương trình khác không khả dụng trong ứng dụng di động.'");
	
	Result.ErrorAttachingAddIn = True;
	Result.DetailedErrorDescription = ErrorMessageString;
	Result.ErrorShortInfo = ErrorMessageString;
	
	Return Result;
	
#Else
	
	If ConnectionUnavailable Then
		Result.Connection = Undefined;
		Result.ErrorShortInfo = ErrorShortInfo;
		Result.DetailedErrorDescription = ErrorShortInfo;
		Return Result;
	EndIf;
	
	Try
		COMConnector = New COMObject(CommonUseClientServer.COMConnectorName()); // "V83.COMConnector"
	Except
		Information = ErrorInfo();
		ErrorMessageString = NStr("en='Не удалось подключится к другой программе: %1';ru='Не удалось подключится к другой программе: %1';vi='Không kết nối được với chương trình khác: %1'");
		
		Result.ErrorAttachingAddIn = True;
		Result.DetailedErrorDescription = StringFunctionsClientServer.SubstituteParametersInString(ErrorMessageString, DetailErrorDescription(Information));
		Result.ErrorShortInfo = StringFunctionsClientServer.SubstituteParametersInString(ErrorMessageString, BriefErrorDescription(Information));
		
		Return Result;
	EndTry;
	
	FileModeWork = Parameters.InfobaseOperationMode = 0;
	
	// Проверка корректности указания параметров.
	FillCheckingError = False;
	If FileModeWork Then
		
		If IsBlankString(Parameters.InfobaseDirectory) Then
			ErrorMessageString = NStr("en = 'Не задано месторасположение каталога информационной базы.'; ru = 'Не задано месторасположение каталога информационной базы.'; vi = 'Vị trí của thư mục CSDL không được chỉ định.'");
			FillCheckingError = True;
		EndIf;
		
	Else
		
		If IsBlankString(Parameters.Server1CEnterpriseName) Or IsBlankString(Parameters.InfobaseNameOn1CEnterpriseServer) Then
			ErrorMessageString = NStr("en = 'Не заданы обязательные параметры подключения: ""Имя сервера""; ""Имя информационной базы на сервере"".'; ru = 'Не заданы обязательные параметры подключения: ""Имя сервера""; ""Имя информационной базы на сервере"".'; vi = 'Các thông số kết nối bắt buộc không được chỉ định: ""Tên máy chủ""; ""Tên của CSDL trên máy chủ"".'");
			FillCheckingError = True;
		EndIf;
		
	EndIf;
	
	If FillCheckingError Then
		
		Result.DetailedErrorDescription = ErrorMessageString;
		Result.ErrorShortInfo   = ErrorMessageString;
		Return Result;
		
	EndIf;
	
	// Формирование строки соединения.
	ConnectionStringTemplate = "[BaseRow][AuthenticationString]";
	
	If FileModeWork Then
		BaseRow = "File = ""&InfobaseDirectory""";
		BaseRow = StrReplace(BaseRow, "&InfobaseDirectory", Parameters.InfobaseDirectory);
	Else
		BaseRow = "Srvr = ""&Server1CEnterpriseName""; Ref = ""&InfobaseNameOn1CEnterpriseServer""";
		BaseRow = StrReplace(BaseRow, "&Server1CEnterpriseName",                     Parameters.Server1CEnterpriseName);
		BaseRow = StrReplace(BaseRow, "&InfobaseNameOn1CEnterpriseServer", Parameters.InfobaseNameOn1CEnterpriseServer);
	EndIf;
	
	If Parameters.OSAuthentication Then
		AuthenticationString = "";
	Else
		
		If StrFind(Parameters.UserName, """") Then
			Parameters.UserName = StrReplace(Parameters.UserName, """", """""");
		EndIf;
		
		If StrFind(Parameters.UserPassword, """") Then
			Parameters.UserPassword = StrReplace(Parameters.UserPassword, """", """""");
		EndIf;
		
		AuthenticationString = "; Usr = ""&UserName""; Pwd = ""&UserPassword""";
		AuthenticationString = StrReplace(AuthenticationString, "&UserName",    Parameters.UserName);
		AuthenticationString = StrReplace(AuthenticationString, "&UserPassword", Parameters.UserPassword);
	EndIf;
	
	ConnectionString = StrReplace(ConnectionStringTemplate, "[BaseRow]", BaseRow);
	ConnectionString = StrReplace(ConnectionString, "[AuthenticationString]", AuthenticationString);
	
	Try
		Result.Connection = COMConnector.Connect(ConnectionString);
	Except
		Information = ErrorInfo();
		ErrorMessageString = NStr("en='Не удалось подключиться к другой программе: %1';ru='Не удалось подключиться к другой программе: %1';vi='Không kết nối được với chương trình khác: %1'");
		
		Result.ErrorAttachingAddIn = True;
		Result.DetailedErrorDescription     = StringFunctionsClientServer.SubstituteParametersInString(ErrorMessageString, DetailErrorDescription(Information));
		Result.ErrorShortInfo       = StringFunctionsClientServer.SubstituteParametersInString(ErrorMessageString, BriefErrorDescription(Information));
	EndTry;
	
	Return Result;
	
#EndIf
	
EndFunction

#EndRegion

#Region RunExternalApplications

#Region SafeCommandString

Function ContainsUnsafeActions(Val CommandString)
	
	Return StrFind(CommandString, "$") <> 0
		Or StrFind(CommandString, "`") <> 0
		Or StrFind(CommandString, "") <> 0
		Or StrFind(CommandString, ";") <> 0
		Or StrFind(CommandString, "&") <> 0;
	
EndFunction

Function ArrayToCommandString(StartupCommand)
	
	Result = New Array;
	QuotesRequired = False;
	For Each Argument In StartupCommand Do
		
		If Result.Count() > 0 Then 
			Result.Add(" ")
		EndIf;
		
		QuotesRequired = Argument = Undefined
			Or IsBlankString(Argument)
			Or StrFind(Argument, " ")
			Or StrFind(Argument, Chars.Tab)
			Or StrFind(Argument, "&")
			Or StrFind(Argument, "(")
			Or StrFind(Argument, ")")
			Or StrFind(Argument, "[")
			Or StrFind(Argument, "]")
			Or StrFind(Argument, "{")
			Or StrFind(Argument, "}")
			Or StrFind(Argument, "^")
			Or StrFind(Argument, "=")
			Or StrFind(Argument, ";")
			Or StrFind(Argument, "!")
			Or StrFind(Argument, "'")
			Or StrFind(Argument, "+")
			Or StrFind(Argument, ",")
			Or StrFind(Argument, "`")
			Or StrFind(Argument, "~")
			Or StrFind(Argument, "$")
			Or StrFind(Argument, "");
		
		If QuotesRequired Then 
			Result.Add("""");
		EndIf;
		
		Result.Add(StrReplace(Argument, """", """"""));
		
		If QuotesRequired Then 
			Result.Add("""");
		EndIf;
		
	EndDo;
	
	Return StrConcat(Result);
	
EndFunction

#EndRegion

#If Not WebClient And Not MobileClient Then

Function NewWindowsCommandStartFile(CommandString, GetCurrentDirectory, WaitForCompletion, ExecutionEncoding) Export
	
	TextDocument = New TextDocument;
	TextDocument.AddLine("@echo off");
	
	If ValueIsFilled(ExecutionEncoding) Then 
		
		If ExecutionEncoding = "OEM" Then
			ExecutionEncoding = 437;
		ElsIf ExecutionEncoding = "CP866" Then
			ExecutionEncoding = 866;
		ElsIf ExecutionEncoding = "UTF8" Then
			ExecutionEncoding = 65001;
		EndIf;
		
		TextDocument.AddLine("chcp " + Format(ExecutionEncoding, "NG="));
		
	EndIf;
	
	If Not IsBlankString(GetCurrentDirectory) Then 
		TextDocument.AddLine("cd /D """ + GetCurrentDirectory + """");
	EndIf;
	TextDocument.AddLine("cmd /S /C "" " + CommandString + " """);
	
	Return TextDocument;
	
EndFunction

#EndIf

#EndRegion

#Region StringFunctions

Function StringInLatin(Val Value, TransliterationRules) Export
	
	Result = "";
	OnlyUppercaseInString = OnlyUppercaseInString(Value);
	
	For Position = 1 To StrLen(Value) Do
		Char = Mid(Value, Position, 1);
		LatinSymbol = TransliterationRules[Lower(Char)]; // Поиск соответствия без учета регистра.
		If LatinSymbol = Undefined Then
			// Другие символы остаются "как есть".
			LatinSymbol = Char;
		Else
			If OnlyUppercaseInString Then 
				LatinSymbol = Upper(LatinSymbol); // восстанавливаем регистр
			ElsIf Char = Upper(Char) Then
				LatinSymbol = Title(LatinSymbol); // восстанавливаем регистр
			EndIf;
		EndIf;
		Result = Result + LatinSymbol;
	EndDo;
	
	Return Result;
	
EndFunction

Function OnlyUppercaseInString(Value)
	
	For Position = 1 To StrLen(Value) Do
		Char = Mid(Value, Position, 1);
		If Char <> Upper(Char) Then 
			Return False;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction

#EndRegion

#EndRegion
