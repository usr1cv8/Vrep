
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Template = ExchangePlans.ExchangeCompanyManagementAccounting.GetTemplate("DetailedInformationAboutExchange");
	
	HTMLDocumentField = Template.GetText();
	
	Title = NStr("en='Information about data synchronization with 1C:Enterprise Accounting 8 3.0';ru='Информация о синхронизации данных с ""1C: Бухгалтерия предприятия 8, ред. 3.0""';vi='Thông tin về đồng bộ hóa dữ liệu với ""1C:Kế toán doanh nghiệp 8, phiên bản 3.0""'");
	
EndProcedure
