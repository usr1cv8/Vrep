
////////////////////////////////////////////////////////////////////////////////
// PROCEDURE - FORM EVENT HANDLERS

&AtServer
// Procedure - event handler OnCreateAtServer of the form.
//
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Filter.Property("Owner") Then
		
		If ValueIsFilled(Parameters.Filter.Owner) Then
			
			If Not Parameters.Filter.Owner.UseBatches Then
				
				Message = New UserMessage();
				Message.Text = NStr("en='Accounting by batches is not kept for products and services.';ru='Для номенклатуры не ведется учет по партиям!';vi='Đối với mặt hàng không tiến hành kế toán theo lô!'");
				Message.Message();
				Cancel = True;
				
			EndIf;	
			
		EndIf;	
		
	EndIf;	
	
	If Parameters.Filter.Property("ExportDocument",Undefined) Then
		
		If Parameters.Filter.ExportDocument = True Then
			
			
			NewFilter = List.Filter.Items.Add(Type("DataCompositionFilterItem"));
			//NewFilter = List.SettingsComposer.Settings.Filter.Items.Add(Type("DataCompositionFilterItem"));
			NewFilter.LeftValue = New DataCompositionField("QuantityBalance");
			NewFilter.ComparisonType = DataCompositionComparisonType.Greater;			
			NewFilter.RightValue = 0; 	
			NewFilter.Use = True;
			
		EndIf;
		
	EndIf;

		
	SetDynamicListParameters();
	
EndProcedure

&AtServer
// Procedure sets values of the dynamic lists parameters 
//
Procedure SetDynamicListParameters()
	
	Parameters.Property("Company", Company);
	Parameters.Property("StructuralUnit", StructuralUnit);
	Parameters.Property("Cell", Cell);
	Parameters.Property("Date", Date);
	Parameters.Property("Characteristic", Characteristic);
	
	List.Parameters.SetParameterValue("Company", SmallBusinessServer.GetCompany(Company));
	List.Parameters.SetParameterValue("StructuralUnit", StructuralUnit);
	List.Parameters.SetParameterValue("Cell", Cell);
	List.Parameters.SetParameterValue("Date", Date);
	List.Parameters.SetParameterValue("Characteristic", Characteristic);
	
	
	
	
	////Parameters filled in a special way, for example, Company
	//ParemeterCompany = New DataCompositionParameter("Company");
	//
	//For Each ListParameter IN List.Parameters.Items Do
	//	
	//	ObjectAttributeValue = Undefined;
	//	If ListParameter.Parameter = ParemeterCompany Then
	//		
	//		List.Parameters.SetParameterValue(ListParameter.Parameter, SmallBusinessServer.GetCompany(Parameters.Company));
	//		
	//	ElsIf Parameters.Property(ListParameter.Parameter, ObjectAttributeValue) Then
	//		
	//		List.Parameters.SetParameterValue(ListParameter.Parameter, ObjectAttributeValue);
	//		
	//	EndIf;
	//	
	//EndDo;
	
EndProcedure // SetDynamicListParameters()
