#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Function TableOfTNFEAClassifier() Export
	
	IndicatorsTable = New ValueTable;
	
	Template = Catalogs.TNFEAClassifier.GetTemplate("CommodityProductsAndServicesClassifierOfForeignEconomicActivity");
	
	//В полученном макете содержатся значения всех списков используемых в отчете
	//ищем переданный
	List = Template.Areas.Find("Rows");
	
	If List.AreaType = SpreadsheetDocumentCellAreaType.Rows Then
		//заполнение дерева данными списка	
		AreaTop = List.Top;
		AreaBottom = List.Bottom;
		
		ColumnNumber = 1;
		Area = Template.Area(AreaTop - 1, ColumnNumber);
		ColumnName = Area.Text;
		ClassifierCodeLength = 7;
		
		While ValueIsFilled(ColumnName) Do
			
			If ColumnName = "Code" Then
				IndicatorsTable.Columns.Add("Code", New TypeDescription("String", , New StringQualifiers(12)));
			ElsIf ColumnName = "Description" Then
				IndicatorsTable.Columns.Add("Description",New TypeDescription("String", , New StringQualifiers(255)));
			EndIf;	
			
			ColumnNumber = ColumnNumber + 1;
			Area = Template.Area(AreaTop - 1, ColumnNumber);
			ColumnName = Area.Text;
			
		EndDo;
		
		For NumRow = AreaTop To AreaBottom Do
			// Отображаем только элементы
			
			Code = TrimR(Template.Area(NumRow, 1).Text);
			If StrLen(Code) = 2 Then
				Continue;
			EndIf;
			ListRow = IndicatorsTable.Add();
			
			For Each Column In IndicatorsTable.Columns Do
				
				ColumnValue = TrimR(Template.Area(NumRow, IndicatorsTable.Columns.IndexOf(Column) + 1).Text);
				ListRow[Column.Name] = ColumnValue;
				
			EndDo;
			
		EndDo;
	EndIf;
	
	IndicatorsTable.Sort(IndicatorsTable.Columns[0].Name + " ASC");
	
	Return IndicatorsTable;
	
EndFunction

#EndIf