
#Region ProgramInterface

// Функция возвращает цвет, отличающийся от исходного светлотой
//
// Parameters:
//  Color			 - Color	 - исходный цвет
//  ДельтаСветлоты	 - Number - процент изменения светлоты цвета. Значение 100 белый цвет, -100 черный.
// 
// Returns:
//  Color - цвет с измененной светлотой
//
Function ChangeColorWhiteness(Val Color, Val ДельтаСветлоты) Export
	
	If Color.Type <> ColorType.Absolute Then
		Return Color;
	EndIf;
	
	If ДельтаСветлоты >= 0 Then
		КрайнееЗначение = 255;
	Else
		КрайнееЗначение = 0;
	EndIf;
	
	R = Color.R + ДельтаСветлоты * Max(КрайнееЗначение - Color.R, Color.R - КрайнееЗначение) / 100;
	G = Color.G + ДельтаСветлоты * Max(КрайнееЗначение-Color.G, Color.G - КрайнееЗначение) / 100;
	B = Color.B + ДельтаСветлоты * Max(КрайнееЗначение-Color.B, Color.B - КрайнееЗначение) / 100;
	
	Return New Color(R, G, B);
	
EndFunction

// Функция возвращает набор пастельных цветов в порядке их взаимной контрастности
// Returns:
//  Array - массив цветов для использования в сериях на диаграммах
Function DiagramColors() Export
	
	МассивЦветов = New Array;
	
	МассивЦветов.Add(New Color(245, 152, 150));
	МассивЦветов.Add(New Color(142, 201, 249));
	МассивЦветов.Add(New Color(255, 202, 125));
	МассивЦветов.Add(New Color(178, 154, 218));
	МассивЦветов.Add(New Color(163, 214, 166));
	МассивЦветов.Add(New Color(244, 140, 175));
	МассивЦветов.Add(New Color(125, 221, 233));
	МассивЦветов.Add(New Color(255, 242, 128));
	МассивЦветов.Add(New Color(205, 145, 215));
	МассивЦветов.Add(New Color(125, 202, 194));
	
	Return МассивЦветов;
	
EndFunction

// Функция - Цвет по номеру картинки
//
// Parameters:
//  PictureNumber	 - Number	 - номер картинки цвета из библиотеки картинок
// 
// Returns:
//  Color - цвет картинки
//
Function ColorByPictureNumber(PictureNumber) Export
	
	Map = New Map;
	
	Map.Insert(1,  New Color(172,114,94));
	Map.Insert(2,  New Color(208,107,100));
	Map.Insert(3,  New Color(248,58,34));
	Map.Insert(4,  New Color(250,87,60));
	Map.Insert(5,  New Color(255,117,55));
	Map.Insert(6,  New Color(255,173,70));
	Map.Insert(7,  New Color(66,214,146));
	Map.Insert(8,  New Color(22,167,101));
	Map.Insert(9,  New Color(123,209,72));
	Map.Insert(10, New Color(179,220,108));
	Map.Insert(11, New Color(251,233,131));
	Map.Insert(12, New Color(250,209,101));
	Map.Insert(13, New Color(146,225,192));
	Map.Insert(14, New Color(159,225,231));
	Map.Insert(15, New Color(159,198,231));
	Map.Insert(16, New Color(73,134,231));
	Map.Insert(17, New Color(154,156,255));
	Map.Insert(18, New Color(185,154,255));
	Map.Insert(19, New Color(194,194,194));
	Map.Insert(20, New Color(202,189,191));
	Map.Insert(21, New Color(204,166,172));
	Map.Insert(22, New Color(246,145,178));
	Map.Insert(23, New Color(205,116,230));
	Map.Insert(24, New Color(164,122,226));
	
	Return Map[PictureNumber];
	
EndFunction

// Функция - Картинка цвета по номеру картинки
//
// Parameters:
//  PictureNumber	 - Number	 - номер картинки цвета из библиотеки картинок
// 
// Returns:
//  Picture - картинка цвета из библиотеки картинок
//
Function ColorPictureByPictureNumber(PictureNumber) Export
	
	НомерСтрокой = Format(PictureNumber, "ND=2; NLZ=");
	
	Return PictureLib["Color" + НомерСтрокой];
	
EndFunction

#EndRegion
