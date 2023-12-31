////////////////////////////////////////////////////////////////////////////////
// FORM EVENT HANDLERS

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest") Then // Return if the form for analysis is received.
		Return;
	EndIf;
	
	If Parameters.Filter.Property("Ind") Then
		Ind = Parameters.Filter.Ind;
		
		IdentityCard = InformationRegisters.IndividualsDocuments.IdentificationDocument(Ind);
		
		IsIdentity = Not IsBlankString(IdentityCard);
		
		Items.IdentityCard.Height		= ?(IsIdentity, 2, 0);
		IdentityCard = ?(IsIdentity, "Identity card: ", "") + IdentityCard;
		
		Query = New Query;
		Query.SetParameter("Ind",	Ind);
		Query.Text =
		"SELECT TOP 1
		|	IndividualsDocuments.Presentation
		|FROM
		|	InformationRegister.IndividualsDocuments AS IndividualsDocuments
		|WHERE
		|	IndividualsDocuments.Ind = &Ind";
		AreDocuments = Not Query.Execute().IsEmpty();
		
		If Not IsIdentity AND AreDocuments Then
			Items.NoneIdentity.Visible		= True;
			MessageText = NStr("en='ID document is not specified for individual %1.';ru='Для физлица %1 не задан документ, удостоверяющий личность.';vi='Đối với cá nhân %1, chưa chỉ ra giấy tờ tùy thân.'");
			IdentityCard = StringFunctionsClientServer.SubstituteParametersInString(MessageText, Ind);
		EndIf;
		
		Items.IdentityCard.Visible	= Not IsBlankString(IdentityCard);
	EndIf;
	
EndProcedure
