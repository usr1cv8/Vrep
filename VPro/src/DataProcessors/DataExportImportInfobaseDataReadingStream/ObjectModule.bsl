#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region LocalVariables

Var CurrentInitialization;
Var CurrentFileName;
Var ReadStream;
Var CurrentObject;
Var CurrentArtifacts;

#EndRegion

#Region ServiceProgramInterface

Procedure OpenFile(Val FileName) Export
	
	If CurrentInitialization Then
		
		Raise NStr("en='The object has already been initialized earlier.';ru='Объект уже был инициализирован ранее!';vi='Đã khởi tạo đối tượng từ trước!'");
		
	Else
		
		CurrentFileName = FileName;
		
		ReadStream = New XMLReader();
		ReadStream.OpenFile(FileName);
		ReadStream.MoveToContent();

		If ReadStream.NodeType <> XMLNodeType.StartElement
			Or ReadStream.Name <> "Data" Then
			
			Raise(NStr("en='XML reading error. Invalid file format. Awaiting Data item start.';ru='Ошибка чтения XML. Неверный формат файла. Ожидается начало элемента Data.';vi='Lỗi đọc XML. Sai định dạng tệp. Thiếu lúc bắt đầu phần tử Data.'"));
		EndIf;

		If Not ReadStream.Read() Then
			Raise(NStr("en='XML reading error. File end is detected.';ru='Ошибка чтения XML. Обнаружено завершение файла.';vi='Lỗi đọc XML. Tìm thấy sự kết thúc tệp.'"));
		EndIf;
		
		//
		
		CurrentInitialization = True;
		
	EndIf;
	
EndProcedure

Function ReadInfobaseDataObject() Export
	
	If ReadStream.NodeType = XMLNodeType.StartElement Then
		
		If ReadStream.Name <> "DumpElement" Then
			Raise NStr("en='XML reading error. Invalid file format. Awaiting DumpElement item start.';ru='Ошибка чтения XML. Неверный формат файла. Ожидается начало элемента DumpElement.';vi='Lỗi đọc XML. Sai định dạng tệp. Dự tính bắt đầu phần tử DumpElement.'");
		EndIf;
		
		ReadStream.Read(); // <DumpElement>
		
		CurrentArtifacts = New Array();
		
		If ReadStream.Name = "Artefacts" Then
			
			ReadStream.Read(); // <Artefacts>
			While ReadStream.NodeType <> XMLNodeType.EndElement Do
				
				URIElement = ReadStream.NamespaceURI;
				ItemName = ReadStream.Name;
				ArtifactType = XDTOFactory.Type(URIElement, ItemName);
				
				Try
					
					ArtifactFragment = ReadFlowFragment();
					ArtifactReadStream = FragmentReadStream(ArtifactFragment);
					
					Artifact = XDTOFactory.ReadXML(ArtifactReadStream, ArtifactType);
					
				Except
					
					OriginalException = DetailErrorDescription(ErrorInfo());
					XMLReaderCallException(ArtifactFragment, OriginalException);
					
				EndTry;
				
				CurrentArtifacts.Add(Artifact);
				
			EndDo;
			ReadStream.Read(); // </Artefacts>
			
		EndIf;
		
		Try
			
			ObjectFragment = ReadFlowFragment();
			ObjectReadStream = FragmentReadStream(ObjectFragment);
			
			CurrentObject = XDTOSerializer.ReadXML(ObjectReadStream);
			
		Except
			
			OriginalException = DetailErrorDescription(ErrorInfo());
			XMLReaderCallException(ObjectFragment, OriginalException);
			
		EndTry;
		
		ReadStream.Read(); // </DumpElement>
		
		Return True;
		
	Else
		
		CurrentObject = Undefined;
		CurrentArtifacts = Undefined;
		
		Return False;
		
	EndIf;
	
EndFunction

Function CurrentObject() Export
	
	Return CurrentObject;
	
EndFunction

Function CurrentObjectArtifacts() Export
	
	Return CurrentArtifacts;
	
EndFunction

#EndRegion

#Region ServiceProceduresAndFunctions

// The current item of the XML reader is being copied.
//
// Parameters:
// ReadStream - XMLReader - Export reader.
//
// Returns:
// String - XML fragment.
//
Function ReadFlowFragment()
	
	WriteFragment = New XMLWriter;
	WriteFragment.SetString();
	
	FragmentNodeName = ReadStream.Name;
	
	RootNode = True;
	Try
		
		While Not (ReadStream.NodeType = XMLNodeType.EndElement
				AND ReadStream.Name = FragmentNodeName) Do
			
			WriteFragment.WriteCurrent(ReadStream);
			
			If ReadStream.NodeType = XMLNodeType.StartElement Then
				
				If RootNode Then
					NamespaceURI = ReadStream.NamespaceContext.NamespaceURI();
					For Each URI IN NamespaceURI Do
						WriteFragment.WriteNamespaceMapping(ReadStream.NamespaceContext.FindPrefix(URI), URI);
					EndDo;
					RootNode = False;
				EndIf;
				
				ElementNamespaceURIPrefixes = ReadStream.NamespaceContext.NamespaceMappings();
				For Each KeyAndValue IN ElementNamespaceURIPrefixes Do
					Prefix = KeyAndValue.Key;
					URI = KeyAndValue.Value;
					WriteFragment.WriteNamespaceMapping(Prefix, URI);
				EndDo;
				
			EndIf;
			
			ReadStream.Read();
		EndDo;
		
		WriteFragment.WriteCurrent(ReadStream);
		
		ReadStream.Read();
	Except
		TextEL = ServiceTechnologyIntegrationWithSSL.SubstituteParametersInString(
			NStr("en='An error occurred while copying a fragment of the source file. Partially copied"
"fragment:% 1';ru='Ошибка копирования фрагмента исходного файла. Частично"
"скопированный фрагмент: %1';vi='Lỗi sao chép đoạn tệp gốc. Một phần"
"đoạn sao chép: %1'"),
				WriteFragment.Close());
		WriteLogEvent(NStr("en='Import/export data.XML reading error';ru='Выгрузка/загрузка данных.Ошибка чтения XML';vi='Việc kết xuất/kết nhập dữ liệu. Lỗi đọc XML'", 
			ServiceTechnologyIntegrationWithSSL.MainLanguageCode()), EventLogLevel.Error, , , TextEL);
		Raise;
	EndTry;
	
	Fragment = WriteFragment.Close();
	
	Return Fragment;
	
EndFunction

Function FragmentReadStream(Val Fragment)
	
	FragmentReading = New XMLReader();
	FragmentReading.SetString(Fragment);
	FragmentReading.MoveToContent();
	
	Return FragmentReading;
	
EndFunction

Procedure XMLReaderCallException(Val Fragment, Val ErrorText)
	
	Raise StringFunctionsClientServer.SubstituteParametersInString(
		NStr("en='An error occurred while reading data from file %1: while reading fragment "
""
"%2"
""
"an error occurred:"
""
"%3.';ru='Ошибка при чтении данных из файла %1: при чтении фрагмента %2"
""
"произошла"
""
"ошибка:"
""
"%3.';vi='Lỗi khi đọc dữ liệu từ tệp %1: khi đọc đoạn %2"
""
"đã xảy ra"
""
"lỗi:"
""
"%3.'"),
		CurrentFileName,
		Fragment,
		ErrorText
	);
	
EndProcedure

#EndRegion

CurrentInitialization = False;

#EndIf