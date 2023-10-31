
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AutoTest") Then
		Return;
	EndIf;
	
	Parameters.Property("CurrentEncoding", CurrentEncoding);
	
	ShowOnlyMainEncodings = True;
	FillEncodingsList(NOT ShowOnlyMainEncodings);
	
EndProcedure

#EndRegion

#Region HeaderFormItemsEventsHandlers

&AtClient
Procedure ShowMainEncodingsOnlyOnChange(Item)
	
	FillEncodingsList(NOT ShowOnlyMainEncodings);
	
EndProcedure

#EndRegion

#Region FormTableItemEventHandlersEncodingList

&AtClient
Procedure EncodingListChoice(Item, SelectedRow, Field, StandardProcessing)
	
	CloseFormWithEncodingReturn();
	
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure SelectEncoding(Command)
	
	CloseFormWithEncodingReturn();
	
EndProcedure

#EndRegion

#Region ServiceProceduresAndFunctions

&AtClient
Procedure CloseFormWithEncodingReturn()
	
	Presentation = Items.EncodingsList.CurrentData.Presentation;
	If Not ValueIsFilled(Presentation) Then
		Presentation = Items.EncodingsList.CurrentData.Value;
	EndIf;
	
	ChoiceResult = New Structure;
	ChoiceResult.Insert("Value", Items.EncodingsList.CurrentData.Value);
	ChoiceResult.Insert("Presentation", Presentation);
	
	NotifyChoice(ChoiceResult);
	
EndProcedure

&AtServer
Procedure FillEncodingsList(FullList)
	
	ItemID = Undefined;
	EncodingsListLocal = Undefined;
	EncodingsList.Clear();
	
	If Not FullList Then
		EncodingsListLocal = FileOperationsService.GetEncodingsList();
	Else
		EncodingsListLocal = GetEncodingsFullList();
	EndIf;
	
	For Each Encoding IN EncodingsListLocal Do
		
		ItemOfList = EncodingsList.Add(Encoding.Value, Encoding.Presentation);
		
		If Lower(Encoding.Value) = Lower(CurrentEncoding) Then
			ItemID = ItemOfList.GetID();
		EndIf;
		
	EndDo;
	
	If ItemID <> Undefined Then
		Items.EncodingsList.CurrentRow = ItemID;
	EndIf;
	
EndProcedure

// Returns encoding names table.
//
// Returns:
//   Values table
//
&AtServerNoContext
Function GetEncodingsFullList()

	EncodingsList = New ValueList;
	
	EncodingsList.Add("Adobe-Standard-Encoding");
	EncodingsList.Add("Big5");
	EncodingsList.Add("Big5-HKSCS");
	EncodingsList.Add("BOCU-1");
	EncodingsList.Add("CESU-8");
	EncodingsList.Add("cp1006");
	EncodingsList.Add("cp1025");
	EncodingsList.Add("cp1097");
	EncodingsList.Add("cp1098");
	EncodingsList.Add("cp1112");
	EncodingsList.Add("cp1122");
	EncodingsList.Add("cp1123");
	EncodingsList.Add("cp1124");
	EncodingsList.Add("cp1125");
	EncodingsList.Add("cp1131");
	EncodingsList.Add("cp1386");
	EncodingsList.Add("cp33722");
	EncodingsList.Add("cp437");
	EncodingsList.Add("cp737");
	EncodingsList.Add("cp775");
	EncodingsList.Add("cp850");
	EncodingsList.Add("cp851");
	EncodingsList.Add("cp852");
	EncodingsList.Add("cp855");
	EncodingsList.Add("cp856");
	EncodingsList.Add("cp857");
	EncodingsList.Add("cp858");
	EncodingsList.Add("cp860");
	EncodingsList.Add("cp861");
	EncodingsList.Add("cp862");
	EncodingsList.Add("cp863");
	EncodingsList.Add("cp864");
	EncodingsList.Add("cp865");
	EncodingsList.Add("cp866",   NStr("en='CP866 (Cyrillic DOS)';ru='CP866 (Кириллица DOS)';vi='CP866 (Cyrillic DOS)'"));
	EncodingsList.Add("cp868");
	EncodingsList.Add("cp869");
	EncodingsList.Add("cp874");
	EncodingsList.Add("cp875");
	EncodingsList.Add("cp922");
	EncodingsList.Add("cp930");
	EncodingsList.Add("cp932");
	EncodingsList.Add("cp933");
	EncodingsList.Add("cp935");
	EncodingsList.Add("cp937");
	EncodingsList.Add("cp939");
	EncodingsList.Add("cp949");
	EncodingsList.Add("cp949c");
	EncodingsList.Add("cp950");
	EncodingsList.Add("cp964");
	EncodingsList.Add("ebcdic-ar");
	EncodingsList.Add("ebcdic-de");
	EncodingsList.Add("ebcdic-dk");
	EncodingsList.Add("ebcdic-he");
	EncodingsList.Add("ebcdic-xml-us");
	EncodingsList.Add("EUC-JP");
	EncodingsList.Add("EUC-KR");
	EncodingsList.Add("GB_2312-80");
	EncodingsList.Add("gb18030");
	EncodingsList.Add("GB2312");
	EncodingsList.Add("GBK");
	EncodingsList.Add("hp-roman8");
	EncodingsList.Add("HZ-GB-2312");
	EncodingsList.Add("IBM01140");
	EncodingsList.Add("IBM01141");
	EncodingsList.Add("IBM01142");
	EncodingsList.Add("IBM01143");
	EncodingsList.Add("IBM01144");
	EncodingsList.Add("IBM01145");
	EncodingsList.Add("IBM01146");
	EncodingsList.Add("IBM01147");
	EncodingsList.Add("IBM01148");
	EncodingsList.Add("IBM01149");
	EncodingsList.Add("IBM037");
	EncodingsList.Add("IBM1026");
	EncodingsList.Add("IBM1047");
	EncodingsList.Add("ibm-1047_P100-1995,swaplfnl");
	EncodingsList.Add("ibm-1129");
	EncodingsList.Add("ibm-1130");
	EncodingsList.Add("ibm-1132");
	EncodingsList.Add("ibm-1133");
	EncodingsList.Add("ibm-1137");
	EncodingsList.Add("ibm-1140_P100-1997,swaplfnl");
	EncodingsList.Add("ibm-1142_P100-1997,swaplfnl");
	EncodingsList.Add("ibm-1143_P100-1997,swaplfnl");
	EncodingsList.Add("ibm-1144_P100-1997,swaplfnl");
	EncodingsList.Add("ibm-1145_P100-1997,swaplfnl");
	EncodingsList.Add("ibm-1146_P100-1997,swaplfnl");
	EncodingsList.Add("ibm-1147_P100-1997,swaplfnl ");
	EncodingsList.Add("ibm-1148_P100-1997,swaplfnl");
	EncodingsList.Add("ibm-1149_P100-1997,swaplfnl");
	EncodingsList.Add("ibm-1153");
	EncodingsList.Add("ibm-1153_P100-1999,swaplfnl");
	EncodingsList.Add("ibm-1154");
	EncodingsList.Add("ibm-1155");
	EncodingsList.Add("ibm-1156");
	EncodingsList.Add("ibm-1157");
	EncodingsList.Add("ibm-1158");
	EncodingsList.Add("ibm-1160");
	EncodingsList.Add("ibm-1162");
	EncodingsList.Add("ibm-1164");
	EncodingsList.Add("ibm-12712_P100-1998,swaplfnl");
	EncodingsList.Add("ibm-1363");
	EncodingsList.Add("ibm-1364");
	EncodingsList.Add("ibm-1371");
	EncodingsList.Add("ibm-1388");
	EncodingsList.Add("ibm-1390");
	EncodingsList.Add("ibm-1399");
	EncodingsList.Add("ibm-16684");
	EncodingsList.Add("ibm-16804_X110-1999,swaplfnl");
	EncodingsList.Add("IBM278");
	EncodingsList.Add("IBM280");
	EncodingsList.Add("IBM284");
	EncodingsList.Add("IBM285");
	EncodingsList.Add("IBM290");
	EncodingsList.Add("IBM297");
	EncodingsList.Add("IBM367");
	EncodingsList.Add("ibm-37_P100-1995,swaplfnl");
	EncodingsList.Add("IBM420");
	EncodingsList.Add("IBM424");
	EncodingsList.Add("ibm-4899");
	EncodingsList.Add("ibm-4909");
	EncodingsList.Add("ibm-4971");
	EncodingsList.Add("IBM500");
	EncodingsList.Add("ibm-5123");
	EncodingsList.Add("ibm-803");
	EncodingsList.Add("ibm-8482");
	EncodingsList.Add("ibm-867");
	EncodingsList.Add("IBM870");
	EncodingsList.Add("IBM871");
	EncodingsList.Add("ibm-901");
	EncodingsList.Add("ibm-902");
	EncodingsList.Add("IBM918");
	EncodingsList.Add("ibm-971");
	EncodingsList.Add("IBM-Thai");
	EncodingsList.Add("IMAP-mailbox-name");
	EncodingsList.Add("ISO_2022,locale=ja,version=3");
	EncodingsList.Add("ISO_2022,locale=ja,version=4");
	EncodingsList.Add("ISO_2022,locale=ko,version=1");
	EncodingsList.Add("ISO-2022-CN");
	EncodingsList.Add("ISO-2022-CN-EXT");
	EncodingsList.Add("ISO-2022-JP");
	EncodingsList.Add("ISO-2022-JP-2");
	EncodingsList.Add("ISO-2022-KR");
	EncodingsList.Add("iso-8859-1",   NStr("en='ISO-8859-1 (Western European ISO)';ru='ISO-8859-1 (Западноевропейская ISO)';vi='ISO-8859-1 (ISO Tây Âu)'"));
	EncodingsList.Add("iso-8859-13");
	EncodingsList.Add("iso-8859-15");
	EncodingsList.Add("iso-8859-2",   NStr("en='ISO-8859-2 (Central European ISO)';ru='ISO-8859-2 (Центральноевропейская ISO)';vi='ISO-8859-2 (ISO Trung Âu)'"));
	EncodingsList.Add("iso-8859-3",   NStr("en='ISO-8859-3 (Latin 3 ISO)';ru='ISO-8859-3 (Латиница 3 ISO)';vi='ISO-8859-3 (3 ISO Latin)'"));
	EncodingsList.Add("iso-8859-4",   NStr("en='ISO-8859-4 (Baltic ISO)';ru='ISO-8859-4 (Балтийская ISO)';vi='ISO-8859-4 (ISO Baltic)'"));
	EncodingsList.Add("iso-8859-5",   NStr("en='ISO-8859-5 (Cyrillic ISO)';ru='ISO-8859-5 (Кириллица ISO)';vi='ISO-8859-5 (ISO Cyrillic)'"));
	EncodingsList.Add("iso-8859-6");
	EncodingsList.Add("iso-8859-7",   NStr("en='ISO-8859-7 (Greek ISO)';ru='ISO-8859-7 (Греческая ISO)';vi='ISO-8859-7 (ISO Hy Lạp)'"));
	EncodingsList.Add("iso-8859-8");
	EncodingsList.Add("iso-8859-9",   NStr("en='ISO-8859-9 (Turkish ISO)';ru='ISO-8859-9 (Турецкая ISO)';vi='ISO-8859-9 (ISO Thổ Nhĩ Kỳ)'"));
	EncodingsList.Add("JIS_Encoding");
	EncodingsList.Add("koi8-r",       NStr("en='KOI8-R (Cyrillic KOI8-R)';ru='KOI8-R (Кириллица KOI8-R)';vi='KOI8-R (KOI8-R Cyrillic)'"));
	EncodingsList.Add("koi8-u",       NStr("en='KOI8-U (Cyrillic KOI8-U)';ru='KOI8-U (Кириллица KOI8-U)';vi='KOI8-U (KOI8-U Cyrillic)'"));
	EncodingsList.Add("KSC_5601");
	EncodingsList.Add("LMBCS-1");
	EncodingsList.Add("LMBCS-11");
	EncodingsList.Add("LMBCS-16");
	EncodingsList.Add("LMBCS-17");
	EncodingsList.Add("LMBCS-18");
	EncodingsList.Add("LMBCS-19");
	EncodingsList.Add("LMBCS-2");
	EncodingsList.Add("LMBCS-3");
	EncodingsList.Add("LMBCS-4");
	EncodingsList.Add("LMBCS-5");
	EncodingsList.Add("LMBCS-6");
	EncodingsList.Add("LMBCS-8");
	EncodingsList.Add("macintosh");
	EncodingsList.Add("SCSU");
	EncodingsList.Add("Shift_JIS");
	EncodingsList.Add("us-ascii",     NStr("en='US-ASCII (USA)';ru='US-ASCII (США)';vi='US-ASCII (Mỹ)'"));
	EncodingsList.Add("UTF-16");
	EncodingsList.Add("UTF16_OppositeEndian");
	EncodingsList.Add("UTF16_PlatformEndian");
	EncodingsList.Add("UTF-16BE");
	EncodingsList.Add("UTF-16LE");
	EncodingsList.Add("UTF-32");
	EncodingsList.Add("UTF32_OppositeEndian");
	EncodingsList.Add("UTF32_PlatformEndian");
	EncodingsList.Add("UTF-32BE");
	EncodingsList.Add("UTF-32LE");
	EncodingsList.Add("UTF-7");
	EncodingsList.Add("UTF-8",        NStr("en='UTF-8 (Unicode UTF-8)';ru='UTF-8 (Юникод UTF-8)';vi='UTF-8 (Unicode UTF-8)'"));
	EncodingsList.Add("windows-1250", NStr("en='Windows-1250 (Central European Windows)';ru='Windows-1250 (Центральноевропейская Windows)';vi='Windows-1250 (Windows Trung Âu)'"));
	EncodingsList.Add("windows-1251", NStr("en='Windows-1251 (Cyrillic Windows)';ru='Windows-1251 (Кириллица Windows)';vi='Windows-1251 (Windows Cyrillic)'"));
	EncodingsList.Add("windows-1252", NStr("en='Windows-1252 (Western European Windows)';ru='Windows-1252 (Западноевропейская Windows)';vi='Windows-1252 (Windows Tây Âu)'"));
	EncodingsList.Add("windows-1253", NStr("en='Windows-1253 (Greek Windows)';ru='Windows-1253 (Греческая Windows)';vi='Windows-1253 (Windows Hy Lạp)'"));
	EncodingsList.Add("windows-1254", NStr("en='Windows-1254 (Turkish Windows)';ru='Windows-1254 (Турецкая Windows)';vi='Windows-1254 (Windows Thổ Nhĩ Kỳ)'"));
	EncodingsList.Add("windows-1255");
	EncodingsList.Add("windows-1256");
	EncodingsList.Add("windows-1257", NStr("en='Windows-1257 (Baltic Windows)';ru='Windows-1257 (Балтийская Windows)';vi='Windows-1257 (Windows Baltic)'"));
	EncodingsList.Add("windows-1258");
	EncodingsList.Add("windows-57002");
	EncodingsList.Add("windows-57003");
	EncodingsList.Add("windows-57004");
	EncodingsList.Add("windows-57005");
	EncodingsList.Add("windows-57007");
	EncodingsList.Add("windows-57008");
	EncodingsList.Add("windows-57009");
	EncodingsList.Add("windows-57010");
	EncodingsList.Add("windows-57011");
	EncodingsList.Add("windows-874");
	EncodingsList.Add("windows-949");
	EncodingsList.Add("windows-950");
	EncodingsList.Add("x-mac-centraleurroman");
	EncodingsList.Add("x-mac-cyrillic");
	EncodingsList.Add("x-mac-greek");
	EncodingsList.Add("x-mac-turkish");
	
	Return EncodingsList;

EndFunction

#EndRegion
