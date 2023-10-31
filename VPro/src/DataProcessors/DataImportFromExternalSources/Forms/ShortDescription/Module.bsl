&AtServer
Procedure FillDetails(TemplateName)
	
	Template = DataProcessors.DataImportFromExternalSources.GetTemplate(TemplateName);
	Template.TemplateLanguageCode = "en";
	Description = Template.GetText();
	
	Description = StrReplace(Description, ">IMPORT FROM EXTERNAL SOURCE<", NStr("en = '>IMPORT FROM EXTERNAL SOURCE<'; ru = '>ЗАГРУЗКА ИЗ ВНЕШНЕГО ИСТОЧНИКА<'; vi = '>KẾT NHẬP DỮ LIỆU TỪ NGUỒN NGOÀI<'"));
	Description = StrReplace(Description, ">COUNTERPARTIES<", NStr("en = '>COUNTERPARTIES<'; ru = '>КОНТРАГЕНТЫ<'; vi = '>ĐỐI TÁC<'"));
	Description = StrReplace(Description, ">PRODUCTS AND SERVICES<", NStr("en = '>PRODUCTS AND SERVICES<'; ru = '>ПРОДУКЦИЯ И УСЛУГИ<'; vi = '>MẶT HÀNG<'"));
	Description = StrReplace(Description, ">PRICES<", NStr("en = '>PRICES<'; ru = '>ЦЕНЫ<'; vi = '>BẢNG GIÁ<'"));
	Description = StrReplace(Description, ">More information about data import...<", NStr("en = '>More information about data import...<'; ru = '>Подробнее о загрузке данных...<'; vi = '>Thông tin chi tiết về kết nhập dữ liệu...<'"));
	Description = StrReplace(Description, ">Movie tutorial<", NStr("en = '>Movie tutorial<'; ru = '>Видео пример<'; vi = '>Video hướng dẫn<'"));
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	FillDetails("QuickStart");
	
EndProcedure

&AtClient
Procedure ShortDescriptionOnClick(Item, EventData, StandardProcessing)
	
	If ValueIsFilled(EventData.Element.id) Then
		
		StandardProcessing = False;
		
		CommandID = EventData.Element.id;
		If Find(CommandID, "Counterparties") > 0 Then
			
			OpenForm("Catalog.Counterparties.ListForm");
			
		ElsIf Find(CommandID, "Products") > 0 Then
			
			OpenForm("Catalog.ProductsAndServices.ListForm");
			
		ElsIf Find(CommandID, "Prices") > 0 Then
			
			OpenForm("DataProcessor.PriceList.Form");
			
		ElsIf Find(CommandID, "ShortAbbreviation") > 0 Then
			
			FillDetails("ShortDescription");
			
		ElsIf Find(CommandID, "QuickStart") > 0 Then
			
			FillDetails("QuickStart");
			
		EndIf;
		
	EndIf;
	
EndProcedure
