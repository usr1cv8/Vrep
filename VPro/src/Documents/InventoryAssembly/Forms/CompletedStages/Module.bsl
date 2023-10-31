
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not GetFunctionalOption("UseProductionStages") Then
		Cancel = True;
		Return;
	EndIf; 
	
	//СтруктураОткрытия.Вставить("ConnectionKey", ConnectionKey);
	//СтруктураОткрытия.Вставить("CompletedStages", StagesArray);
	//СтруктураОткрытия.Вставить("Specification", CurrentData.Specification);
	
	If Not Parameters.Property("Specification") 
		Or Not Parameters.Property("CompletedStages")
		Or Not Parameters.Property("ConnectionKey", ConnectionKey) Then
		Cancel = True;
		Return;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Specification", Parameters.Specification);
	Query.SetParameter("CompletedStages", Parameters.CompletedStages);
	Query.Text =
	"SELECT
	|	ProductionKindsStages.LineNumber AS LineNumber,
	|	ProductionKindsStages.Stage AS Stage,
	|	CASE
	|		WHEN ProductionKindsStages.Stage IN (&CompletedStages)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS Label
	|FROM
	|	Catalog.Specifications AS Specifications
	|		LEFT JOIN Catalog.ProductionKinds.Stages AS ProductionKindsStages
	|		ON Specifications.ProductionKind = ProductionKindsStages.Ref
	|WHERE
	|	Specifications.Ref = &Specification
	|
	|UNION ALL
	|
	|SELECT
	|	0,
	|	ProductionStages.Ref,
	|	TRUE
	|FROM
	|	Catalog.ProductionStages AS ProductionStages
	|WHERE
	|	NOT ProductionStages.Ref IN
	|				(SELECT
	|					ProductionKindsStages.Stage
	|				FROM
	|					Catalog.Specifications AS Specifications
	|						LEFT JOIN Catalog.ProductionKinds.Stages AS ProductionKindsStages
	|						ON
	|							Specifications.ProductionKind = ProductionKindsStages.Ref
	|				WHERE
	|					Specifications.Ref = &Specification)
	|	AND ProductionStages.Ref IN(&CompletedStages)
	|
	|ORDER BY
	|	ProductionKindsStages.LineNumber";
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		CompletedStages.Add(Selection.Stage, , Selection.Label);
	EndDo;
	
EndProcedure

#EndRegion 

#Region FormCommandHandlers

&AtClient
Procedure Select(Command)
	
	StageArray = New Array;
	For Each Element In CompletedStages Do
		If Not Element.Check Then
			Continue;
		EndIf;
		If StageArray.Find(Element.Value) <> Undefined Then
			Continue;
		EndIf;
		StageArray.Add(Element.Value);
	EndDo;
	
	Result = New Structure;
	Result.Insert("ConnectionKey", ConnectionKey);
	Result.Insert("CompletedStages", StageArray);
	
	NotifyChoice(Result);
	
EndProcedure

#EndRegion 
 

