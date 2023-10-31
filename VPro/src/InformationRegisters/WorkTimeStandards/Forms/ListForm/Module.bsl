////////////////////////////////////////////////////////////////////////////////
// PROCEDURE - FORM EVENT HANDLERS

&AtServer
// Procedure-handler of the OnCreateAtServer event.
// Performs initial attributes forms filling.
//
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("Filter") AND Parameters.Filter.Property("ProductsAndServices") Then

		ProductsAndServices = Parameters.Filter.ProductsAndServices;

		If ProductsAndServices.ProductsAndServicesType <> Enums.ProductsAndServicesTypes.Work Then
			
			AutoTitle = False;
			Title = NStr("en='Standard hours are stored only for works';ru='Нормы времени хранятся только для работ';vi='Định mức thời gian chỉ được lưu đối với công việc'");

			Items.List.ReadOnly = True;
			
		ElsIf ProductsAndServices.FixedCost Then
			
			AutoTitle = False;
			Title = NStr("en='""Work cost calculation method"" should be ""Standard time""';ru='""Способ расчета стоимости работ"" должен быть ""Норма времени""';vi='""Cách tính giá trị công việc"" cần phải là ""Định mức thời gian""'");

			Items.List.ReadOnly = True;
			
		EndIf;

	EndIf;
		
EndProcedure // OnCreateAtServer()
