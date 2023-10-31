
#Region ProgramInterface

Function FormLetteringBasisDocument(Val BasisDocument, Val pViewOnly = False) Export
	
	FSComponents = New Array;
	
	BasisDocDescription = WorkWithDocumentForm.BasisDocumentDescription(BasisDocument);
	
	If BasisDocDescription = "NoObject" Then
		
		FSComponents = New Array;
		FSComponents.Add(New FormattedString(NStr("en='Basis: located in autonomous workplace';vi='Cơ sở: đặt tại nơi làm việc tự chủ'")));
		
	ElsIf ValueIsFilled(BasisDocument) Then
			
		BasisDocumentText = BasisDocDescription;
		
		BasisDocumentText = StrReplace(BasisDocumentText, NStr("en='(deleted)';ru='(удалено)';vi='(đã xóa)'"),"");
		BasisDocumentText = StrReplace(BasisDocumentText, NStr("en='(not posted)';vi='(chưa kết chuyển)'"),"");

		FSComponents = New Array;
		FSComponents.Add(New FormattedString(NStr("En='null';vi='không'")));
		FSComponents.Add(New FormattedString(BasisDocumentText, , , , NStr("en='open';vi='mở'")));
		If Not pViewOnly Then
			FSComponents.Add(New FormattedString(" "));
			FSComponents.Add(New FormattedString(PictureLib.FillByBasis12х12, , , , NStr("en='fill';vi='điền'")));
			FSComponents.Add(New FormattedString(" "));
			FSComponents.Add(New FormattedString(PictureLib.Clear, , , , NStr("en='delete';vi='xóa'")));
		EndIf;
	Else
		FSComponents = New Array;
		FSComponents.Add(New FormattedString(NStr("en='Basis: ';vi='Cơ sở:'")));
		FSComponents.Add(New FormattedString(NStr("en='select';vi='chọn'"), , , , NStr("en='select';vi='chọn'")));
	EndIf;
	
	Return New FormattedString(FSComponents);

EndFunction

Function ShortPresentationOfVATTaxationType(VATTaxation) Export
	
	If VATTaxation = PredefinedValue("Enum.VATTaxationTypes.TaxableByVAT") Then
		Return NStr("en='with VAT';ru='с НДС';vi='gồm thuế GTGT'");
	ElsIf VATTaxation = PredefinedValue("Enum.VATTaxationTypes.NotTaxableByVAT") Then
		Return NStr("en='without VAT';ru='без НДС';vi='không gồm thuế GTGT'");
	ElsIf VATTaxation = PredefinedValue("Enum.VATTaxationTypes.ForExport") Then
		Return NStr("en='0% VAT';ru='0% НДС';vi='0% thuế GTGT'");
	Else
		Return "";
	EndIf;
	
EndFunction

#EndRegion

#Region ServiceMethods

Function GetShortDocumentNumber(Val DocNumber) Export
	
	NumericNumber = New Map();
	NumericNumber.Insert("1",1);
	NumericNumber.Insert("2",2);
	NumericNumber.Insert("3",3);
	NumericNumber.Insert("4",4);
	NumericNumber.Insert("5",5);
	NumericNumber.Insert("6",6);
	NumericNumber.Insert("7",7);
	NumericNumber.Insert("8",8);
	NumericNumber.Insert("9",9);
	NumericNumber.Insert("0",0);
	
	DocNumber = TrimAll(DocNumber);
	LineLenght = StrLen(DocNumber);
	Number = DocNumber;
	
	For n=1 To LineLenght Do
	
		If NumericNumber.Get(Mid(DocNumber,LineLenght-n+1,1)) = Undefined Then
			Number = Right(DocNumber, n-1); 
			Break;
		EndIf;
	
	EndDo;
	
	If StrLen(Number)>0 Then
		Return Number(Number);
	Else
		Return DocNumber;
	EndIf;
	
EndFunction

Function StringFormName(Val FormName) Export
	
	FormName = StrReplace(FormName, ".ListForm", "");
	FormName = StrReplace(FormName, ".DocumentForm", "");
	FormName = StrReplace(FormName, ".ChoiceForm", "");
	FormName = StrReplace(FormName, ".ItemForm", "");
	FormName = StrReplace(FormName, ".Form", "");
	
	FormName = StrReplace(FormName, ".", "");
	
	Return FormName;
	
EndFunction

#EndRegion
