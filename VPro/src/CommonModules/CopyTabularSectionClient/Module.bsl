////////////////////////////////////////////////////////////////////////////////
// Клиентские процедуры и функции для копирования и вставки 
// строк табличных частей
//
////////////////////////////////////////////////////////////////////////////////

#Region ProgramInterface

// Проверяет возможность копирования строк в буфер обмена.
//
// Parameters:
//  TabSec              - FormDataCollection - Таблица формы, в которой происходит копирование строк.
//  CurrentTSData - FormDataCollectionItem - Текущие данные таблицы.
// Returns:
//  Boolean - Истина, если копирование строк возможно.
Function CopyRowsAvailable(TabSec, CurrentTSData) Export
	
	If CurrentTSData <> Undefined And TabSec.Count() <> 0 Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

// Оповещает пользователя о количестве скопированных строк в буфер обмена.
//
// Parameters:
//  NumberOfCopied - Number - Количество скопированных строк.
Procedure NotifyUserAboutCopyingRows(NumberOfCopied) Export
	
	ShowUserNotification(
		NStr("en='Строки скопированы';ru='Строки скопированы';vi='Đã sao chép các dòng'"),,
		StrTemplate(
			NStr("en='В буфер обмена скопированы строки (%1)';ru='В буфер обмена скопированы строки (%1)';vi='Đã sao chép các dòng (%1) vào bộ đệm trung gian'"),
			NumberOfCopied),
		PictureLib.Information32);
	
	Notify("ClipboardTabularSectionRowsCopying");
	
EndProcedure

// Оповещает пользователя о количестве вставленных строк в таблицу из буфера обмена.
//
// Parameters:
//  Форма                   - ФормаКлиентскогоПриложения - Форма, на которой располагается таблица.
//  NumberOfCopied - Number - Количество скопированных строк.
//  КоличествоСкопированных - Число - Количество вставленных строк.
Procedure NotifyUserOnInsertRows(NumberOfCopied, NumberOfInserted) Export
	
	ShowUserNotification(
		NStr("en='Строки вставлены';ru='Строки вставлены';vi='Đã chèn các dòng'"),,
		StrTemplate(
			NStr("en='Из буфера обмена вставлены строки (%1 из %2)';ru='Из буфера обмена вставлены строки (%1 из %2)';vi='Đã chèn các dòng (%1 trong số %2) từ bộ đệm trung gian'"),
			NumberOfInserted,
			NumberOfCopied),
		PictureLib.Information32);
	
EndProcedure

// form event handler "NotificationProcessing".
//
// Parameters:
//  Items - FormAllItems - Элементы формы, на которой расположены кнопки копирования и вставки строк.
//  TSName    - String - Имя таблицы формы, в которой буду производиться встака/копирование строк.
Procedure NotificationProcessing(Items, TSName) Export
	
	SetButtonsVisibility(Items, TSName, True);
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

// Устанавливает доступность кнопок вставки и копирования строк в табличную часть.
Procedure SetButtonsVisibility(Controls, TSName, HasCopiedRows)
	
	Controls[TSName + "CopyRows"].Enabled = True;
	
	If HasCopiedRows Then
		Controls[TSName + "InsertRows"].Enabled = True;
	Else
		Controls[TSName + "InsertRows"].Enabled = False;
	EndIf;
	
EndProcedure

#EndRegion
