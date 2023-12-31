
#Region ServiceProceduresAndFunctions

&AtClient
Procedure SearchStringInTable(SearchForward)
	
	If IsBlankString(SearchString) Then
		
		ShowMessageBox( , NStr("en='Search string is not set';ru='Не задана строка поиска';vi='Chưa chỉ ra dòng tìm kiếm'"), CommonUseClientServer.MainLanguageCode());
		CurrentItem = Items.SearchString;
		Return;
		
	EndIf;
	
	FoundArea = Classifier.FindText(TrimAll(SearchString), Items.Classifier.CurrentArea, , , , SearchForward, True);
	If FoundArea = Undefined Then
		
		FoundArea = Classifier.FindText(TrimAll(SearchString), , , , , , True);
		If FoundArea = Undefined Then
			
			MessageText = NStr("en='Unit of measure is not found';ru='Единица измерения не найдена';vi='Không tìm thấy đơn vị tính'", CommonUseClientServer.MainLanguageCode());
			CommonUseClientServer.MessageToUser(MessageText, , "SearchString");
			CurrentItem = Items.SearchString;
			Return;
			
		EndIf;
		
	EndIf;
	
	CurrentItem = Items.Classifier;
	
	AreaArray = New Array;
	AreaArray.Add(FoundArea);
	Items.Classifier.SetSelectedAreas(AreaArray);
	
EndProcedure

&AtClient
Procedure ExecuteCase(CurrentArea, CloseForm = True)
	
	NumericalCode				= Classifier.Area(CurrentArea.Top, AreaNumericalCodeLeft, CurrentArea.Bottom, AreaNumericalCodeRight).Text;
	ShortDescription		= Classifier.Area(CurrentArea.Top, AreaShortDescriptionLeft, CurrentArea.Bottom, AreaShortDescriptionRight).Text;
	DescriptionFull		= Classifier.Area(CurrentArea.Top, AreaDescriptionFullLeft, CurrentArea.Bottom, AreaDescriptionFullRight).Text;
	InternationalAbbreviation = Classifier.Area(CurrentArea.Top, AreaCodeAlphabeticInternationalLeft, CurrentArea.Bottom, AreaCodeAlphabeticInternationalRight).Text;
	
	MessageText = "";
	If IsBlankString(NumericalCode) Then
		
		MessageText = NStr("en='numeric code';ru='числовой код';vi='mã bằng số'");
		
	EndIf;
	
	If IsBlankString(ShortDescription) Then
		
		MessageText = MessageText + ?(IsBlankString(MessageText), "", ", ") + NStr("en='short name';ru='краткое наименование';vi='tên gọi vắn tắt'");
		
	EndIf;
	
	If IsBlankString(DescriptionFull) Then
		
		MessageText = MessageText + ?(IsBlankString(MessageText), "", ", ") + NStr("en='full name';ru='полное наименование';vi='tên gọi đầy đủ'");
		
	EndIf;
	
	If Not IsBlankString(MessageText) Then
		
		MessageText = NStr("en='Resulting cell is not specified (indicators are not filled: ';ru='Указана не результирующая ячейка (не заполнены показатели: ';vi='Hãy chỉ ra ô không chứa kết quả (chưa điền chỉ số):'") + MessageText + NStr("en=')';ru=')';vi=')'");
		CommonUseClientServer.MessageToUser(MessageText, , "Classifier");
		CloseForm = False;
		Return;
		
	EndIf;

	FillingValues = New Structure;
	FillingValues.Insert("Code", NumericalCode);
	FillingValues.Insert("Description", StrGetLine(ShortDescription, 1));
	FillingValues.Insert("DescriptionFull", StrGetLine(DescriptionFull, 1));
	FillingValues.Insert("InternationalAbbreviation", StrGetLine(InternationalAbbreviation, 1));
	
	FormParameters = New Structure("FillingValues", FillingValues);
	
	UnOfMeas = SearchExistingUnit(FormParameters);
	If UnOfMeas <> Undefined Then
		
		FormParameters.Insert("Key", UnOfMeas);
		OpenForm("Catalog.UOMClassifier.Form.ItemForm", FormParameters, ThisForm);
		WarningText = NStr("en='Unit of measure was added earlier.';ru='Единица измерения была добавлена раннее.';vi='Đơn vị tính đã được thêm vào từ trước.'", CommonUseClientServer.MainLanguageCode());
		ShowMessageBox(, WarningText, , );
		CloseForm = False;
		
	Else
		
		AddedItem = Undefined;
		CreateMeasurementUnitByClassifier(FillingValues);
		Notify("ChoiceMeasurementUnitFromClassifier", AddedItem, ThisForm);
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function SearchExistingUnit(Val FormParameters)
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	UOMClassifier.Ref
	|FROM
	|	Catalog.UOMClassifier AS UOMClassifier
	|WHERE
	|	UOMClassifier.Code = &Code";
	
	Query.SetParameter("Code", FormParameters.FillingValues.Code);
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.Ref;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

&AtServer
Procedure CreateMeasurementUnitByClassifier(FillingValues)
	
	Try
		
		MeasurementUnitByClassifier = Catalogs.UOMClassifier.CreateItem();
		FillPropertyValues(MeasurementUnitByClassifier, FillingValues);
		MeasurementUnitByClassifier.Write();
		AddedItem = MeasurementUnitByClassifier.Ref;
		
	Except
		
		WriteLogEvent(NStr("en='Add units of measure from RNCMU';ru='Добавление единиц измерения из ОКЕИ';vi='Thêm đơn vị đo lường từ Bảng mã hiệu đơn vị đo lường'", CommonUseClientServer.MainLanguageCode()), EventLogLevel.Error, , , ErrorDescription());
		
	EndTry;
	
EndProcedure

#EndRegion

#Region FormEvents

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("SearchString") Then
		SearchString = TrimAll(Parameters.SearchString);
	EndIf;
	
	Template = Catalogs.UOMClassifier.GetTemplate("UOMClassifier");
	Classifier.Put(Template);
	Classifier.FixedTop = 1;
	
	AreaNumericalCodeLeft = Template.Areas.NumericalCode.Left;
	AreaNumericalCodeRight = Template.Areas.NumericalCode.Right;
	AreaShortDescriptionLeft = Template.Areas.ShortDescription.Left;
	AreaShortDescriptionRight = Template.Areas.ShortDescription.Right;
	AreaDescriptionFullLeft = Template.Areas.DescriptionFull.Left;
	AreaDescriptionFullRight = Template.Areas.DescriptionFull.Right;
	AreaCodeAlphabeticInternationalLeft = Template.Areas.CodeLetterInternational.Left;
	AreaCodeAlphabeticInternationalRight = Template.Areas.CodeLetterInternational.Right;
	
	If Not IsBlankString(SearchString) Then
		
		FoundArea = Classifier.FindText(SearchString,, Classifier.Areas.NumericalCode,,,, True);
		Items.Classifier.CurrentArea = FoundArea;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormAttributesEvents

&AtClient
Procedure SearchStringOnChange(Item)
	
	SearchStringInTable(True);
	
EndProcedure

&AtClient
Procedure ClassifierSelection(Item, Area, StandardProcessing)
	
	CloseForm	= True;
	Area			= Items.Classifier.CurrentArea;
	
	ExecuteCase(Area, CloseForm);
	If CloseForm Then
		
		Close();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region CommandHandlers

&AtClient
Procedure Select(Command)
	
	Area = Items.Classifier.CurrentArea;
	ExecuteCase(Area);
	
EndProcedure

&AtClient
Procedure ChooseAndClose(Command)
	
	CloseForm	= True;
	Area 		= Items.Classifier.CurrentArea;
	
	ExecuteCase(Area, CloseForm);
	If CloseForm Then
		
		Close();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SearchBack(Command)
	
	SearchStringInTable(False);
	
EndProcedure

&AtClient
Procedure SearchForward(Command)
	
	SearchStringInTable(True);
	
EndProcedure

#EndRegion

