-- Задание №1
-- В каких городах больше одного аэропорта?

SELECT city AS "Город"
      , COUNT(airport_name) AS "Количество аэропортов"
FROM bookings.airports
GROUP BY city
HAVING COUNT(airport_name) > 1

-- Логика: В запросе используется представление airports т.к. оно визуально гармоничнее представляет итоговый результат.
		-- При выводе используется аггрегатная функция COUNT, с помощью которой ведётся подсчёт количества аэропортов в конкретном городе.
		-- Оператор GROUP BY группирует города при выборке.
        -- Оператор HAVING фильтрует (накладывает условие, для того,что бы в результате запроса были выведены города с количеством аэропортов больше 1)
        	-- результат группировки, сделанной с помощью команды GROUP BY.


-- Задание №2
-- В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью перелета?

-- Требования к запросу: использвание подзапроса.

-- 1 способ
-- explaIN analyse -- cost (стоимость) = 1847.96 , actual time (время выполнения) = 16.729
SELECT DISTINCT airport_code AS "Код аэропорта"
			   , airport_name AS "Название аэропорта"
FROM bookings.flights AS fl JOIN (
                                  SELECT aircraft_code
								  FROM aircrafts_data
								  ORDER BY "range" DESC
								  LIMIT 1
								 ) AS aircrafts_d USING (aircraft_code)
						    JOIN (
						          SELECT airport_code
						                , airport_name 
						    	  FROM bookings.airports_data
						    	 ) AS airports_d ON fl.departure_airport = airports_d.airport_code 

-- 2 способ
-- explaIN analyse -- cost (стоимость) = 1683.78 , actual time (время выполнения) = 8.910						    	  
SELECT DISTINCT airport_code, airport_name
FROM bookings.flights AS fl JOIN (
                                  SELECT airport_code
                                        , airport_name 
						    	  FROM bookings.airports_data
						    	 ) AS airports_d ON fl.departure_airport = airports_d.airport_code
WHERE aircraft_code = (
                       SELECT aircraft_code
					   FROM bookings.aircrafts_data
					   ORDER BY "range" DESC
					   LIMIT 1
					  )
					   
-- Логика:
-- 1 способ: Таблица flights является связующим звеном таблиц aircrafts_data и airports_data (таблицы, в которых хранятся необходимые данные),
		        -- поэтому к данной таблице джойним необходимые нам таблицы по сответствующим полям, при этом в SELECT выводим только поля,
		        -- необходимые для анализа.
			 -- USING используется когда наименование столбцов идентичные.
			 -- В первом подзапросе (где выводятся данные из таблицы aircrafts_data) происходит сортировка в порядке убывания
			    -- по range (максимальной дальности полета) и выводится первое максимальное значение.

-- 2 способ: Таблица flights является связующим звеном таблиц aircrafts_data и airports_data (таблицы, в которых хранятся необходимые данные),
		        -- поэтому к данной таблице джойним таблицу airports_data по сответствующему полю, при этом в SELECT выводим только поля,
		        -- необходимые для анализа.
			 -- В общем услови реализуемого запроса, знчения поля aircraft_code приравниваем к полученным значениям подзапроса.
			 -- В подзапросе (где выводятся данные из таблицы aircrafts_data) происходит сортировка в порядке убывания
			    -- по range (максимальной дальности полета) и выводится первое максимальное значение.

-- Наиболее оптимальным решением данной задачи является 2 способ, т.к. он сбалансированние по затраченным ресурсам и быстрее по скорости выполнения.
					   

-- Задание №3
-- Вывести 10 рейсов с максимальным временем задержки вылета.

-- Требования к запросу: использвание оператора LIMIT.
					   
SELECT flight_id AS "Идентификатор рейса"
	  , flight_no AS "Номер рейса"
	  , scheduled_departure AS "Время вылета по расписанию"
	  , actual_departure AS "Фактическое время вылета"
	  , actual_departure - scheduled_departure AS "Время задержки рейса"
FROM bookings.flights
WHERE actual_departure IS NOT NULL
     AND scheduled_departure IS NOT NULL
ORDER BY "Время задержки рейса" DESC
LIMIT 10

-- Логика: Все необходимые данные сожердатся в таблице flights.
         -- В выборку попадают только те рейсы, у которых введено время вылета по расписанию и фактическое время вылета.
         -- Время задержки рейса считается как разность между фактическим временем вылета и временем вылета по расписанию.
         -- Далее происход сортировка в порядке убывания по задрежке времени рейса и выводятся первые 10 значений.


-- Задание №4
-- Были ли брони, по которым не были получены посадочные талоны?

-- Требования к подзапросу: Верный тип JOIN.

SELECT CASE WHEN boarding_no IS NULL THEN 'Посадочный талон не получен'
            ELSE 'Посадочный талон получен'
            END AS "Наличие посадочного талона"
      , COUNT (DISTINCT bp.book_ref) AS "Количество"
FROM bookings.bookings AS bp JOIN (
                                   SELECT ticket_no
                                         , book_ref
								   FROM bookings.tickets
								  ) AS bt USING (book_ref)
                             JOIN (
                                   SELECT ticket_no
								   FROM bookings.ticket_flights
								  ) AS tf USING (ticket_no) 
                             LEFT JOIN (
                                        SELECT boarding_no
                                              , ticket_no
								        FROM bookings.boarding_passes
								       ) AS bo_pa USING (ticket_no) 
WHERE boarding_no IS NULL
GROUP BY CASE WHEN boarding_no IS NULL THEN 'Посадочный талон не получен'
              ELSE 'Посадочный талон получен'
              END											  
											  
-- Логика: Для анализа исследуемых данных джойним друг к другу несколько таблиц при помощи оператора JOIN - bookings, tickets, ticket_flights,
		      -- при этом происходит объединение записей из двух таблиц по связующему полю, если оно содержит одинаковые значения в обеих таблицах;
		      -- затем джойним таблицу boarding_passes при помощи оператора LEFT JOIN, который создает левое внешнее соединение. С помощью левого
		      -- внешнего соединения выбираются все записи первой (левой) таблицы (т.е. присоединённых друг к другу таблиц bookings, tickets,
		      -- ticket_flights), даже если они не соответствуют записям во второй (правой) таблице (boarding_passes), причем в подзапросах джоина
		      -- выводим только те поля, которые необходимы для анализа.
           -- Условие (where) прописываем т.о., что бы в выборку попали только те брони, по которым не были получены посадочные талоны.
           -- Агрегатная функция COUNT подсчитываем количество уникальных броней, по которым не были получены посадочные талоны.
           -- Оператором case осуществляем проверку наличия посадочного талона по каждой брони (если Номер посадочного талона null, значит посадочный
              -- талон не получен, если иначе - получен).
           -- Оператор GROUP BY группирует результат проверки наличия посадочного талона.
           

-- Задание №5
-- Найдите количество свободных мест для каждого рейса, их % отношение к общему количеству мест в самолете.
-- Добавьте столбец с накопительным итогом - суммарное накопление количества вывезенных пассажиров из каждого аэропорта на каждый день.
    -- Т.е. в этом столбце должна отражаться накопительная сумма - сколько человек уже вылетело из данного аэропорта на этом или более ранних рейсах в течении дня.

-- Требования к запросу: использование оконной функции, подзапросов или/и cte.
           
WITH max_seats AS (
                   SELECT aircraft_code
						 , COUNT (seat_no) AS "Всего мест в самолёте"
				   FROM bookings.seats
                   GROUP BY aircraft_code
                  ),
     count_pass AS (
                    SELECT bo_pa.flight_id
                          , flight_no
                          , aircraft_code
                          , departure_airport
                          , actual_departure
                          , COUNT(bo_pa.boarding_no) AS "Количество занятых мест в самолёте" 
     			    FROM bookings.boarding_passes AS bo_pa JOIN (
     			                                                 SELECT flight_id
     			    												   , flight_no
     			    												   , aircraft_code
     			    												   , departure_airport
     			    												   , actual_departure
     			    											 FROM bookings.flights
     			    											 WHERE actual_departure IS NOT NULL
     			    											) AS fl USING (flight_id)
     			    GROUP BY bo_pa.flight_id
     			    		, flight_no
     			    		, aircraft_code
     			    		, departure_airport
     			    		, actual_departure
     			   )
SELECT departure_airport AS "Аэропорт отправления"
      , flight_no AS "Номер рейса"
	  , actual_departure  AS "Фактическое время вылета"
      , "Количество занятых мест в самолёте"
	  , "Всего мест в самолёте"
	  , ("Всего мест в самолёте" - "Количество занятых мест в самолёте") AS "Количество свободных мест"
	  , (ROUND(("Всего мест в самолёте" - "Количество занятых мест в самолёте") / "Всего мест в самолёте" :: DEC, 2) * 100) AS "% отношение свободных мест"
      , SUM("Количество занятых мест в самолёте") OVER (PARTITION BY departure_airport , cast (actual_departure AS DATE) ORDER BY actual_departure) AS "Накопительная сумма пассажиров"
FROM bookings.max_seats AS ms JOIN (
                                    SELECT flight_no
								          , aircraft_code
                          		          , departure_airport
                          		          , actual_departure
                          		          , "Количество занятых мест в самолёте" 
						            FROM bookings.count_pass
						           ) AS cp USING (aircraft_code)

-- Логика: Для решения поставленной заачи будем использовать оператор WITH, который заключается в разбиении сложных запросов на простые части.
		   -- Подзапрос max_seats рассчитывает общее количество мест в самолёте.
		   -- Подзапрос count_pass определяет количество выданных посадочных талонов путем соединения к таблице boarding_passes таблицы flights
		      -- по первичному ключу flight_id. Причем в подзапросе fl накладывается условие - должно быть указано фактическое время вылета, чтобы понимать
			  -- что выле был осуществлён.
		   -- В итоговом подзапросе СTE джойнятся два подзапроса СТЕ max_seats и count_pass по столбцу aircraft_code и выводятся необходимые столбцы.
           -- Количество свободных мест рассчитывается как разность между "Всего мест в самолёте" и "Количество занятых мест в самолёте"/
           -- Процентное соотношение свободных мест рассчитвается как частное Количества свободных мест от Общего количества мест в самолёте умноженное 
              -- на 100; (ROUND - функция округления, :: dec, 2 - дробное число, хранящееся в виде строки (2 - количество отводимых под число символов)).
           -- Для подсчета накопительной суммы используется оконная функция c подразделением на подгруппы по аэропорту отправления и фактическому времени
              -- вылета (время переведено в формат DATE).


-- Задание №6
-- Найдите процентное соотношение перелетов по типам самолетов от общего количества.

-- Требования к запросу: Подзапрос или окно; Оператор ROUND.

SELECT model ->> 'ru' AS "Модель самолёта"
	   , ROUND (
	            COUNT (flight_id) / (
	                                 SELECT COUNT (flight_id)
	   								 FROM bookings.flights
	   								 WHERE actual_departure IS NOT NULL
	   								) :: DEC * 100, 2
	   		   ) AS "% перелетов по типам самолетов"
FROM bookings.aircrafts_data AS ad JOIN (
                                         SELECT flight_id
									           , aircraft_code
								         FROM bookings.flights
								         WHERE actual_departure IS NOT NULL
								        ) AS fl USING (aircraft_code)
GROUP BY model
						   
-- Логика: Для реализаци поставленной задачи необхдимо к таблице aircrafts_data (необходим столбец с моделью самолёта) приджойнить таблицу flights (необходим
		      -- столбец с идентификатором рейса. Данные талицы соединяются по полю aircraft_code.
		   -- Процентное соотношение перелетов по типам самолетов от общего количества реализовано при помощи деления идентификатора рейса в разрезе типов
		      -- смололётов на общее количество рейсов умноженное на 100.
		   -- При расчёте процентного соотношения перелетов по типам самолетов от общего количества был применён оператор ROUND, который округляет найденное
		      -- число до двух знаков после запятой. Так же при расчете данного показателя не были учтены отменённые рейсы (т.е. рейсы, у которых отсутствует
		      -- фактическое время вылета).
		   -- model ->> 'ru' - возвращение значения в формате text по ключу (json) 


-- Задание №7
-- Были ли города, в которые можно добраться бизнес - классом дешевле, чем эконом-классом в рамках перелета?

-- Требования к запросу: использование CTE.

WITH min_business AS (
                      SELECT flight_id
							, MIN(amount) AS min_business
					  FROM bookings.ticket_flights
                      WHERE fare_conditions IN ('Business')
                      GROUP BY flight_id
                     ),
     max_economy AS (
                     SELECT flight_id
     						, MAX(amount) AS max_economy
					 FROM bookings.ticket_flights
                     WHERE fare_conditions IN ('Economy')
                     GROUP BY flight_id
                    )
SELECT min_b.flight_id
      , city ->> 'ru'
	  , min_business
	  , max_economy
FROM min_business AS min_b JOIN max_economy AS max_e USING (flight_id)
						   JOIN (
						         SELECT flight_id
						               , arrival_airport 
						   		 FROM bookings.flights
						   		) AS fl USING (flight_id)
						   JOIN (
						         SELECT airport_code
						               , city
						   		 FROM bookings.airports_data
						   		) AS ad ON ad.airport_code = fl.arrival_airport
WHERE min_business < max_economy

-- Логика: Для реализации поставленной задачи было использовано СТЕ.
           -- В подзапросе СТЕ min_business выводятся идентефикатор рейса, минимальная стоимость билета бизнес-класса.
           -- В подзапросе СТЕ max_economy выводятся идентефикатор рейса, максимальная стоимость билета эконом класа.
           -- В основном запросе к таблцие min_business джойнятся таблицы max_economy (по обзщему столбцу flight_id),
              -- а так же таблицы:
           	  --   - flights (по первичному ключу flight_id, с выводом необходимых столбцов);
           	  --   - airports_data (код аэропорта равен коду аэропорта прилёта, с выводом необходимых столбцов).
           -- Таблица flights и airports_data джойнятся с целью вывести город, в резульате запроса.
           -- city ->> 'ru' - возвращение значения в формате text по ключу (json).
           -- В основном запросе в условии WHERE прописывается, что минимальная стоимость билета бизнес-класса должна быть
              -- меньше максимальной стоимости билета эконом класса.
           -- В нашем случае запрос выдал пустые строки, это значит нет городов, в которые можно добраться бизнес-классом
              -- дешевле, чем эконом-классом в рамках перелета. 


-- Задание №8
-- Между какими городами нет прямых рейсов?

-- Требования к запросу: 
      -- - Декартово произведение в предложении FROM;
      -- - Самостоятельно созданные представления (если облачное подключение, то без представления);
      -- - Оператор EXCEPT.

SELECT ad1.city ->> 'ru' AS "Город отправления"
      , ad2.city ->> 'ru' AS "Город прибытия"
FROM bookings.airports_data AS ad1, bookings.airports_data AS ad2
WHERE ad1.city != ad2.city
except
SELECT "Город отправления" ->> 'ru' AS "Город отправления"
      , "Город прибытия" ->> 'ru' AS "Город прибытия"
FROM bookings.flights AS fl JOIN (
								  SELECT city AS "Город отправления"
                                        , airport_code   
								  FROM bookings.airports_data
								 ) AS ad_dep ON fl.departure_airport = ad_dep.airport_code
							JOIN (
							      SELECT city AS "Город прибытия", airport_code   
								  FROM bookings.airports_data
								 ) AS ad_arr ON fl.arrival_airport = ad_arr.airport_code

-- Логика: Для реализации поставленной задачи использовался оператор EXCEPT, который возвращает все строки, которые есть в результате первого запроса,
              -- но отсутствуют в результате второго.
		   -- В первом (в верхнем, до except) запросе при помощи декартова произведения в предложении FROM получаем всевозможные пересечения всех городов,
		      -- с наложением условия, что город отправления не может равнятся городу прибытия.
		   -- Во втором (в нижнем, после except) запросе выводятся города отправления и прибытия, между которыми осуществляются прямые перелёты, для вывода
		      -- данных джойним таблицу airports_data несколько раз (в первом случае по аэропорту отправления, во втором - по аэропорту прибытия) к таблице
		      -- flights.
		   -- В результате выполнения запроса, были выведены города, между которыми нет прямых рейсов (т.е. из результата первого запроса вычли результат
		      -- второго запроса, причем с уникальными значениями).
		      

-- Задание №9
-- Вычислите расстояние между аэропортами, связанными прямыми рейсами, сравните с допустимой максимальной дальностью перелетов  в самолетах, обслуживающих
   -- эти рейсы *.
-- * - В облачной базе координаты находятся в столбце airports_data.coordinates - работаете, как с массивом. В локальной базе координаты находятся
      -- в столбцах airports.longitude и airports.latitude.
-- Кратчайшее расстояние между двумя точками A и B на земной поверхности (если принять ее за сферу) определяется зависимостью:
								  
          -- d = arccos {sin(latitude_a)·sin(latitude_b) + cos(latitude_a)·cos(latitude_b)·cos(longitude_a - longitude_b)}
								  
   --, где latitude_a и latitude_b — широты
   --      longitude_a, longitude_b — долготы данных пунктов
   --      d — расстояние между пунктами измеряется в радианах длиной дуги большого круга земного шара.
-- Расстояние между пунктами, измеряемое в километрах, определяется по формуле:
          
		  --L = d·R,
								  
   -- где R = 6371 км — средний радиус земного шара.
							
-- Требования к запросу: использование оператор RADIANS или использование SIND/COSD, а так же case

SELECT DISTINCT ad.airport_name ->> 'ru' AS "Аэропорт отправления"
	           , aa.airport_name ->> 'ru' AS "Аэропорт прибытия"
	           , a."range" "Максимальная дальность самолета",
	           , ROUND((acos(SIND(ad.coordinates[1]) * SIND(aa.coordinates[1]) + COSD(ad.coordinates[1]) * COSD(aa.coordinates[1]) * COSD(ad.coordinates[0] - aa.coordinates[0])) * 6371)::dec, 2) AS "Расстояние между аэропортами"		
	           , CASE WHEN a."range" < acos(SIND(ad.coordinates[1]) * SIND(aa.coordinates[1]) + COSD(ad.coordinates[1]) * COSD(aa.coordinates[1]) * COSD(ad.coordinates[0] - aa.coordinates[0])) * 6371 THEN 'Не долетит!'
		              ELSE 'Долетит!'
		              END AS "Итог расчёта"
FROM flights AS f JOIN airports_data AS ad ON f.departure_airport = ad.airport_code
                  JOIN airports_data AS aa ON f.arrival_airport = aa.airport_code
                  JOIN aircrafts_data AS a ON a.aircraft_code = f.aircraft_code 

-- Широта — coordinates[1]
-- Долгота — coordinates[0]
-- SIND - тригонометрическая функиця в градусах (синус)
-- COSD - тригонометрическая функиця в градусах (косинус)

-- Логика: Для реализации поставленной задачи были приджойнены необходимые таблицы.
           -- Расстояние между аэропортами было рассчитано согласно формуле из задания и округлено до сотых при помощи оператора ROUND.
           -- В столбце "Итог расчёта", при помощи оператора case определялось долетит или не долетит самолёт из аэропорта отправления аэропорт
              -- назначения, путем сравнения двух параметров - Максимальной дальности полёта самолёта (т.е. техн.характеристикой) и расстоянием между
              -- аэропортами. Если максимальная дальность перелёта строго меньше расстояния между аэропортами, то самолёт долетит, если иначе - не долетит.


-- Задание №10
-- Сколько суммарно каждый тип самолета провел в воздухе, если брать завершенные перелеты.

SELECT aircraft_code AS "Тип самолёта"
      , SUM (actual_arrival - actual_departure) AS "Время полёта"
FROM bookings.flights AS fl JOIN bookings.aircrafts_data AS ad USING (aircraft_code)
WHERE actual_arrival IS NOT NULL
GROUP BY aircraft_code


-- Задание №11
-- Сколько было получено посадочных талонов по каждой брони

SELECT book_ref AS "Номер бронирования"
      , COUNT (boarding_no) AS "Количество посадочных талонов" 
FROM bookings.bookings AS boo JOIN (
                                    SELECT book_ref
                                          , ticket_no
                                    FROM tickets
                                   ) AS ti USING (book_ref)
                              JOIN (
                                    SELECT boarding_no 
                                          , ticket_no
                                    FROM bookings.boarding_passes
                                   ) AS bp USING (ticket_no)
GROUP BY book_ref


-- Задание №12
-- Вывести общую сумму продаж по каждому классу билетов

SELECT fare_conditions
      , SUM(amount) AS "Сумма продаж" 
FROM bookings.ticket_flights
GROUP BY fare_conditions


-- Задание №13
-- Найти маршрут с наибольшим финансовым оборотом

SELECT ad_dep.airport_name ->> 'ru' AS "Название аэропорта отправления"
      , "Код аэропорта отправления"
      , ad_arr.airport_name ->> 'ru' AS "Название аэропорта прибытия"
      , "Код аэропорта прибытия"
      , SUM(amount) AS "Суммарная стоимость билетов"
FROM bookings.ticket_flights AS tf JOIN (
                                         SELECT flight_id
											   , departure_airport AS "Код аэропорта отправления"
											   , arrival_airport AS "Код аэропорта прибытия"
										 FROM bookings.flights
										) AS fl USING (flight_id)
								   JOIN (
								         SELECT airport_code, airport_name  
								         FROM bookings.airports_data
								        ) AS ad_dep ON fl."Код аэропорта отправления" = ad_dep.airport_code
							       JOIN (
							             SELECT airport_code, airport_name   
								         FROM bookings.airports_data
								        ) AS ad_arr ON fl."Код аэропорта прибытия" = ad_arr.airport_code
GROUP BY ad_dep.airport_name
        ,"Код аэропорта отправления"
        , ad_arr.airport_name
        , "Код аэропорта прибытия"
ORDER BY "Суммарная стоимость билетов" DESC
LIMIT 1


-- Задание №14
-- Найти наилучший и наихудший месяцы по бронированию билетов (количество и сумма)

WITH "Наилучший месяц" AS (
                           SELECT DATE_PART('month', book_date) AS "Месяц"
                                 , SUM(total_amount) AS "Сумма по бронированиям"
                                 , COUNT (book_ref ) AS "Количество бронирований"
                           FROM bookings.bookings
                           GROUP BY DATE_PART('month', book_date)
                           ORDER BY "Сумма по бронированиям" DESC
                           LIMIT 1
                          ),
     "Наихудший месяц" AS (
                           SELECT DATE_PART('month', book_date) AS "Месяц"
                                 , SUM(total_amount) AS "Сумма по бронированиям"
                                 , COUNT (book_ref ) AS "Количество бронирований"
                           FROM bookings.bookings
                           GROUP BY DATE_PART('month', book_date)
                           ORDER BY "Сумма по бронированиям"
                           LIMIT 1
                          )
SELECT * , 'Наилучший месяц' AS "Тип месяца"
FROM "Наилучший месяц"
UNION
SELECT *, 'Наихудший месяц' AS "Тип месяца"
FROM "Наихудший месяц"


-- Задание №15
-- Между какими городами пассажиры делали пересадки? Пересадкой считается нахождение пассажира в промежуточном аэропорту менее 24 часов.

WITH pass AS (
              SELECT tic.ticket_no
                    , fl.departure_airport AS "Код аэропорта отправления"
                    , fl.arrival_airport AS "Код аэропорта прибытия"
                    , fl.actual_departure
                    , fl.actual_arrival
              FROM bookings.tickets AS tic JOIN (
                                                 SELECT ticket_no
                                                       , flight_id
                                                 FROM bookings.ticket_flights
                                                ) AS tf USING (ticket_no)
                                           JOIN (
                                                 SELECT flight_id
                                                       , departure_airport
                                                       , arrival_airport
                                                       , actual_departure
                                                       , actual_arrival
                                                 FROM bookings.flights
                                                ) AS fl USING (flight_id)
             )
SELECT DISTINCT ad_dep.city ->> 'ru' AS "Город отправления"
               , ad_arr.city ->> 'ru' AS "Город прибытия"
FROM pass AS p1 JOIN pass AS p2 ON p2.ticket_no = p1.ticket_no 
                                  AND p1."Код аэропорта прибытия" = p2."Код аэропорта отправления"
                JOIN (
                      SELECT airport_code, city 
					  FROM bookings.airports_data
					 ) AS ad_dep ON p1."Код аэропорта отправления" = ad_dep.airport_code
				JOIN (
				      SELECT airport_code, city   
					  FROM bookings.airports_data
					 ) AS ad_arr ON p2."Код аэропорта прибытия" = ad_arr.airport_code
WHERE ad_dep.city != ad_arr.city
     AND EXTRACT(HOUR FROM p2.actual_departure-p1.actual_arrival) < 24
 