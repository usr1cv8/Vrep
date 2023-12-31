
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("ProductsAndServices") Then
		SmallBusinessClientServer.SetListFilterItem(List, "ProductsAndServices", Parameters.ProductsAndServices);
		If Parameters.ProductsAndServices.ProductsAndServicesType <> Enums.ProductsAndServicesTypes.InventoryItem Then
			AutoTitle = False;
			Title = NStr("en='Barcodes are stored only for inventories';ru='Штрихкоды хранятся только для запасов';vi='Mã vạch chỉ được lưu đối với vật tư'");
			Items.List.ReadOnly = True;
		EndIf;
	EndIf;
	
EndProcedure
