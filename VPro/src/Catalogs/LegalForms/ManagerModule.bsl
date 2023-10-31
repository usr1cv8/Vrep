#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region ServiceProceduresAndFunctions

Procedure FillAvailableLegalForms() Export

	Query = New Query;
	Query.Text = 
		"SELECT TOP 1
		|	LegalForms.Ref AS LegalForm
		|FROM
		|	Catalog.LegalForms AS LegalForms";
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	// 1. LLC
	LegalForm = Catalogs.LegalForms.CreateItem();
	LegalForm.Description	= NStr("en='Limited Liability Company';ru='Общество с ограниченной ответственностью';vi='Công ty trách nhiệm hữu hạn'");
	LegalForm.ShortName		= NStr("en='LLC';ru='ООО';vi='Công ty TNHH'");
	
	InfobaseUpdate.WriteData(LegalForm);
	
	// 2. FZE
	LegalForm = Catalogs.LegalForms.CreateItem();
	LegalForm.Description	= NStr("en='Free Zone Establishment';ru='Непубличное акционерное общество';vi='Công ty cổ phần chưa niêm yết'");
	LegalForm.ShortName		= NStr("en='FZE';ru='АО';vi='Công ty cổ phần'");
	
	InfobaseUpdate.WriteData(LegalForm);
	
	// 3. FZCO
	LegalForm = Catalogs.LegalForms.CreateItem();
	LegalForm.Description	= NStr("en='Free Zone Company';ru='Публичное акционерное общество';vi='Công ty cổ phần đã niêm yết'");
	LegalForm.ShortName		= NStr("en='FZCO';ru='ПАО';vi='Công ty cổ phần đã niêm yết'");
	
	InfobaseUpdate.WriteData(LegalForm);

EndProcedure

#EndRegion

#EndIf