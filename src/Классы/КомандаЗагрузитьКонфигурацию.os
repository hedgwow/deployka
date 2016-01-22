
#Использовать v8runner
#Использовать logos

Перем РежимыОбновления;
Перем ИспользуемаяВерсияПлатформы;
Перем Лог;
Перем ВозможныйРезультат;

///////////////////////////////////////////////////////////////////////////////////////////////////
// Прикладной интерфейс

Процедура ЗарегистрироватьКоманду(Знач ИмяКоманды, Знач Парсер) Экспорт
	
	ОписаниеКоманды = Парсер.ОписаниеКоманды(ИмяКоманды, "Загрузка/обновление конфигурации");
	Парсер.ДобавитьКоманду(ОписаниеКоманды);

	Парсер.ДобавитьПозиционныйПараметрКоманды(ОписаниеКоманды, "СтрокаПодключения", "Строка подключения к рабочему контуру");
    Парсер.ДобавитьПозиционныйПараметрКоманды(ОписаниеКоманды, "ПутьДистрибутива", "Путь к дистрибутиву в виде каталога версии");
    Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "/mode", "Режим обновления:
    	|	-auto - Сначала искать CFU, потом CF
    	|	-cf   - Использовать только CF
    	|	-cfu  - Использовать только CFU
    	|	-load - Полная загрузка конфигурации
    	|	-skip - Не выполнять обновление");

    Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, 
    	"-db-user",
    	"Пользователь информационной базы");

    Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, 
    	"-db-pwd",
    	"Пароль пользователя информационной базы");

    Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, 
    	"-v8version",
    	"Маска версии платформы 1С");

КонецПроцедуры

Функция ВыполнитьКоманду(Знач ПараметрыКоманды) Экспорт	

	СоздатьПеречислениеРежимыОбновления();
	СоздатьПеречислениеВозможныйРезультат();
	
	ТекущийРежим = ВыбратьРежимПоПараметрамКоманды(ПараметрыКоманды["/mode"]);

	Если ТекущийРежим = Неопределено Тогда
		Лог.Ошибка("Неверно задан режим загрузки");
		Возврат ВозможныйРезультат.НеверныеПараметры;
	КонецЕсли;

	Если ТекущийРежим = РежимыОбновления.ПропуститьШаг Тогда
		Лог.Информация("Пропускаю шаг загрузки конфигурации");
		Возврат ВозможныйРезультат.Успех;
	КонецЕсли;

	СтрокаПодключения = ПараметрыКоманды["СтрокаПодключения"];
	ПутьДистрибутива  = ПараметрыКоманды["ПутьДистрибутива"];
	Пользователь      = ПараметрыКоманды["-db-user"];
	Пароль            = ПараметрыКоманды["-db-pwd"];

	ИспользуемаяВерсияПлатформы = ПараметрыКоманды["-v8version"];

	Если ПустаяСтрока(СтрокаПодключения) Тогда
		Лог.Ошибка("Не задана строка подключения");
		Возврат ВозможныйРезультат.НеверныеПараметры;
	КонецЕсли;

	Если ПустаяСтрока(ПутьДистрибутива) Тогда
		Лог.Ошибка("Не задан путь дистрибутива");
		Возврат ВозможныйРезультат.НеверныеПараметры;
	КонецЕсли;

    Попытка
    	Возврат ВыполнитьОбновлениеКонфигурации(СтрокаПодключения, ПутьДистрибутива, Пользователь, Пароль, ТекущийРежим);
    Исключение
    	Лог.Ошибка(ОписаниеОшибки());
    	Возврат ВозможныйРезультат.ОшибкаВремениВыполнения;
    КонецПопытки;

КонецФункции

////////////////////////////////////////////////////////////////////////////////////////////////
// Непосредственное выполнение команды

Функция ВыполнитьОбновлениеКонфигурации(
		Знач СтрокаПодключения,
		Знач ПутьДистрибутива,
		Знач ИмяПользователя,
		Знач ПарольПользователя,
		Знач РежимОбновления)

	Конфигуратор = Новый УправлениеКонфигуратором;
	Конфигуратор.УстановитьКонтекст(СтрокаПодключения, ИмяПользователя, ПарольПользователя);
	Если ИспользуемаяВерсияПлатформы <> Неопределено Тогда
		Конфигуратор.ИспользоватьВерсиюПлатформы(ИспользуемаяВерсияПлатформы);
	КонецЕсли;

	Возврат ОбновитьВВыбранномРежиме(РежимОбновления, Конфигуратор, ПутьДистрибутива);

КонецФункции

Функция ОбновитьВВыбранномРежиме(Знач РежимОбновления, Знач Конфигуратор, Знач ПутьДистрибутива) Экспорт
	
	Лог.Отладка("Режим обновления: " + РежимОбновления);
	Лог.Отладка("Путь дистрибутива: " + ПутьДистрибутива);
	
	Если РежимОбновления = РежимыОбновления.Авто Тогда
		Возврат ВыполнитьАвтоОбновление(Конфигуратор, ПутьДистрибутива);
	ИначеЕсли РежимОбновления = РежимыОбновления.Обновление Тогда
		Возврат ОбновитьПринудительно(Конфигуратор, ПутьДистрибутива);
	ИначеЕсли РежимОбновления = РежимыОбновления.ПолныйДистрибутив Тогда
		Возврат ОбновитьПолнымДистрибутивом(Конфигуратор, ПутьДистрибутива);
	ИначеЕсли РежимОбновления = РежимыОбновления.ЗагрузкаКонфигурации Тогда
		Возврат ЗагрузитьКонфигурацию(Конфигуратор, ПутьДистрибутива);
	Иначе
		ВызватьИсключение "Неизвестный режим обновления";
	КонецЕсли;
КонецФункции

Функция ВыполнитьАвтоОбновление(Знач Конфигуратор, Знач ПутьДистрибутива)
	
		ФайлДистрибутива = НайтиОбязательныйФайл(ПутьДистрибутива, "*.cfu");
		Если ФайлДистрибутива = Неопределено Тогда
			ФайлДистрибутива = НайтиОбязательныйФайл(ПутьДистрибутива, "*.cf");
		КонецЕсли;
		
		Если ФайлДистрибутива = Неопределено Тогда
			Лог.Ошибка(СтрШаблон("Не обнаружен файл конфигурации в каталоге '%1'", ПутьДистрибутива));
			Возврат ВозможныйРезультат.НеверныеПараметры;
		КонецЕсли;
		
		Возврат ОбновитьБазуДанных(Конфигуратор, ФайлДистрибутива);
			
КонецФункции

Функция ОбновитьПринудительно(Знач Конфигуратор, Знач ПутьДистрибутива)
	ФайлДистрибутива = НайтиОбязательныйФайл(ПутьДистрибутива, "*.cfu");
	Если ФайлДистрибутива = Неопределено Тогда
		Лог.Ошибка(СтрШаблон("Не обнаружен файл конфигурации в каталоге '%1'", ПутьДистрибутива));
		Возврат ВозможныйРезультат.НеверныеПараметры;
	КонецЕсли;
	
	Возврат ОбновитьБазуДанных(Конфигуратор, ФайлДистрибутива);
	
КонецФункции

Функция ОбновитьПолнымДистрибутивом(Знач Конфигуратор, Знач ПутьДистрибутива)
	ФайлДистрибутива = НайтиОбязательныйФайл(ПутьДистрибутива, "*.cf");
	Если ФайлДистрибутива = Неопределено Тогда
		Лог.Ошибка(СтрШаблон("Не обнаружен файл конфигурации в каталоге '%1'", ПутьДистрибутива));
		Возврат ВозможныйРезультат.НеверныеПараметры;
	КонецЕсли;
	
	Возврат ОбновитьБазуДанных(Конфигуратор, ФайлДистрибутива);
	
КонецФункции

Функция ЗагрузитьКонфигурацию(Знач Конфигуратор, Знач ПутьДистрибутива)
	
	ФайлДистрибутива = НайтиОбязательныйФайл(ПутьДистрибутива, "*.cf");
	Если ФайлДистрибутива = Неопределено Тогда
		Лог.Ошибка(СтрШаблон("Не обнаружен файл конфигурации в каталоге '%1'", ПутьДистрибутива));
		Возврат ВозможныйРезультат.НеверныеПараметры;
	КонецЕсли;
	
	Попытка
		Конфигуратор.ЗагрузитьКонфигурациюИзФайла(ФайлДистрибутива, Ложь);
		Возврат ВозможныйРезультат.Успех;
	Исключение
		Лог.Ошибка(Конфигуратор.ВыводКоманды());
		Возврат ВозможныйРезультат.ОшибкаВремениВыполнения;
	КонецПопытки;
	
КонецФункции

Функция ОбновитьБазуДанных(Знач Конфигуратор, Знач ФайлДистрибутива)
	
	ПараметрыЗапуска = Конфигуратор.СтандартныеПараметрыЗапускаКонфигуратора();
	
	ПараметрыЗапуска.Добавить("/UpdateCfg");
	ПараметрыЗапуска.Добавить(ОбернутьВКавычки(ФайлДистрибутива));

	Попытка
		Конфигуратор.ВыполнитьКоманду(ПараметрыЗапуска);
		Возврат ВозможныйРезультат.Успех;
	Исключение
		Лог.Ошибка(Конфигуратор.ВыводКоманды());
		Возврат ВозможныйРезультат.ОшибкаВремениВыполнения;
	КонецПопытки;
	
КонецФункции

Функция НайтиОбязательныйФайл(Знач Каталог, Знач Маска)
	
	Файлы = НайтиФайлы(Каталог, Маска);
	Если Файлы.Количество() > 0 Тогда
		Возврат Файлы[0].ПолноеИмя;
	Иначе
		Возврат Неопределено;
	КонецЕсли;
	
КонецФункции

///////////////////////////////////////////////////////////
// Вспомогательные методы

Функция ВыбратьРежимПоПараметрамКоманды(Знач ПараметрРежим)
	Если ПустаяСтрока(ПараметрРежим) или ПараметрРежим = "-auto" Тогда
		Возврат РежимыОбновления.Авто;
	ИначеЕсли ПараметрРежим = "-cf" Тогда
		Возврат РежимыОбновления.ПолныйДистрибутив;
	ИначеЕсли ПараметрРежим = "-cfu" Тогда
		Возврат РежимыОбновления.Обновление;
	ИначеЕсли ПараметрРежим = "-load" Тогда
		Возврат РежимыОбновления.ЗагрузкаКонфигурации;
	ИначеЕсли ПараметрРежим = "-skip" Тогда
		Возврат РежимыОбновления.ПропуститьШаг;
	КонецЕсли;

	Возврат Неопределено;
КонецФункции

Функция СоздатьПеречислениеРежимыОбновления() Экспорт
	РежимыОбновления = Новый Структура;
	РежимыОбновления.Вставить("Авто", 0);
	РежимыОбновления.Вставить("ПолныйДистрибутив", 1);
	РежимыОбновления.Вставить("Обновление", 2);
	РежимыОбновления.Вставить("ЗагрузкаКонфигурации", 3);
	РежимыОбновления.Вставить("ПропуститьШаг", 4);
	Возврат РежимыОбновления;
КонецФункции

Функция СоздатьПеречислениеВозможныйРезультат() Экспорт
	ВозможныйРезультат = МенеджерКомандПриложения.РезультатыКоманд();
	Возврат ВозможныйРезультат;
КонецФункции

Функция ОбернутьВКавычки(Знач Строка)
	Возврат ЗапускПриложений.ОбернутьВКавычки(Строка);
КонецФункции

Лог = Логирование.ПолучитьЛог("vanessa.app.deployka");