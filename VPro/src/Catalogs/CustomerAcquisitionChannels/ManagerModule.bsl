#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region InternalProceduresAndFunctions

// Procedure fills catalog by default
//
Procedure FillAvailableCustomerAcquisitionChannels() Export
	
	Query = New Query;
	Query.Text = 
		"SELECT TOP 1
		|	CustomerAcquisitionChannels.Ref AS Channel
		|FROM
		|	Catalog.CustomerAcquisitionChannels AS CustomerAcquisitionChannels";
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	// 1. Website
	Channel = Catalogs.CustomerAcquisitionChannels.CreateItem();
	Channel.SetNewCode();
	Channel.Description = NStr("en='Website';ru='Сайт';vi='Website'");
	
	InfobaseUpdate.WriteData(Channel);
	
	// 2. E-mail
	Channel = Catalogs.CustomerAcquisitionChannels.CreateItem();
	Channel.SetNewCode();
	Channel.Description = NStr("en='E-mail';ru='E-mail';vi='E-mail'");
	
	InfobaseUpdate.WriteData(Channel);
	
	// 3. Звонок
	Channel = Catalogs.CustomerAcquisitionChannels.CreateItem();
	Channel.SetNewCode();
	Channel.Description = NStr("en='Phone call';ru='Звонок';vi='Cuộc gọi '");
	
	InfobaseUpdate.WriteData(Channel);
	
	// 4. Выставка
	Channel = Catalogs.CustomerAcquisitionChannels.CreateItem();
	Channel.SetNewCode();
	Channel.Description = NStr("en='Exhibition';ru='Выставка';vi='Triển lãm'");
	
	InfobaseUpdate.WriteData(Channel);
	
	// 5. Рекламная кампания
	Channel = Catalogs.CustomerAcquisitionChannels.CreateItem();
	Channel.SetNewCode();
	Channel.Description = NStr("en='Advertising campaign';ru='Рекламная кампания';vi='Công ty quảng cáo'");
	
	InfobaseUpdate.WriteData(Channel);
	
EndProcedure

#EndRegion

#EndIf
