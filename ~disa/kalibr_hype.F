
\ загрузка таблиц калибровок  первый столбец - частота,  "постоянно растущая"
\ нанные пишутся в  действительных числах !!!!!
\ промежуточные данные -  линейно интерполируются 


\ tabl_kalibr NEW "ИМЯ"  = создание новой таблицы
\ "кол-во строк"  "кол-во столбцов" "ИМЯ" LoadDatas:   = инициализация загрузки таблицы  "ИМЯ"
\ 
\  LoadData: х1 х2 ...  \ загрузка данных вариант 1
\ х1 х2 ...х4 LoadData   \ загрузка данных вариант 2 

\ "ИМЯ" SeeDatas   -посмотреть таблицу данных
\  n  TakeData 
\ freq	n "ИМЯ"  TakeData \ получить данные из столбца n  с частотой freq из таблицы "ИМЯ" 

\ -----------------------------------
\  в конце есть   "LoadDatas: " с "перевернутыми" значсениями для удобства загрузки значений из внешнего файла
\ "ИМЯ"  "кол-во строк"  "кол-во столбцов" LoadDatas:   = инициализация загрузки таблицы  "ИМЯ"
\ -----------------------------------


 
S" load kalibr_file.f" TYPE CR

 REQUIRE  N_S_PickUpWord ~disa\dopoln.f
 REQUIRE  F. lib\include\float2.f
 REQUIRE  HYPE ~day\hype3\hype3.f
 REQUIRE  dBuV->V  ~disa/algoritm.f
  REQUIRE S+time savefile.spf

 
0 VALUE tekdata \ однопоточная часть! ??  только для загрузки 


CLASS tabl_kalibr

CELL DEFS  datas \ ссылка на данные
CELL DEFS num_datas  \ количество загруженных ячеек
CELL DEFS max_datas  \ всего ячеек
CELL DEFS num_datas_in_string   \ количество данных в  строке


init:
	 SELF TO tekdata 
	1 num_datas_in_string ! 
	0  num_datas ! \ :SetData  
	1 FLOATS   ALLOCATE THROW   datas !
;
 
: deltaFreq ( freq1 freq2 - flag) \ сравнение 2х  чисел c дельной аналог F= с учетом погрешностей ПК
||   F: freq   ||
freq F! 
freq F@ F- FABS
freq F@ F/ 
1e-5 F>
;



\ для определения частот на границе переключений вводим еще одну частоту\
\ по которой будем определять эту границу
1 FLOATS DEFS  LastFreq    \ предыдущая частота 
1 FLOATS DEFS  LastFreq2    \ пред-предыдущая частота 
\ и слово для запомнинания 
: SaveFreq \ F. 
	 LastFreq F@ LastFreq2 F!
	 LastFreq F! 
;



: adr_data_in_number    \ получить адрес строки по её номеру
	|| D:  N_write ||
	
DUP max_datas @ > IF DROP max_datas @ THEN	
DUP 1 < IF DROP 0 THEN	
N_write ! 	 
\ ." ->" DUP .  N_write @ . ." <-"
	num_datas_in_string @ FLOATS  * datas @ +  N_write @ FLOATS +   
 
;
 

: take_freq_in_number \  получить частоту по её номеру ( первы столбец)
\ матрица  частот и антенных факторов
	\   num_datas_in_string  @ FLOATS * datas @ + SF@
 \ ." ->" DUP . 
 	0  adr_data_in_number  F@  
\ DROP 1e1
\ FDUP F. ." <-"
;

: MinMax \ определение    границ калибровочных файлов и корректировка значения 
	\	<< F: freq -- F:freq1 D: flag >>
	|| F: freq D: flag ||
	freq F! 0 flag !
	 0 take_freq_in_number			freq F@	F> IF  0		take_freq_in_number  freq F! 1 flag ! THEN
	 num_datas @ 1 - take_freq_in_number	freq F@ F< IF  num_datas @ 1 -  take_freq_in_number  freq F! 1 flag ! THEN 
	freq F@ flag @
;


 
:  take_data_in_number  (  n_freq , n_write  -- )
	\  || D:  N_write ||
	\ N_write ! num_datas_in_string @ FLOATS  * datas @ +  N_write @ FLOATS +
	adr_data_in_number  F@ 
;


: FreqNum ( freq -- num) \ определение номера ячейки по частоте
	||   D: n F: freq   ||adr_data_in_number
	freq F!  0 n ! 
	num_datas @ \ количество точек
	0  
	DO
		I  take_freq_in_number  \ CR FDUP F.  ." " I .  n @ . 
		freq  F@ 1.00001E F* F<=  IF I  n !  THEN 
	LOOP
	n @
;

: NextFreq ( freq_old -- freq_new )
	||   D: n F: freq F: newfreq  ||
	freq F!  
	\ проверяем 2 повторения по частоте в таблице  калибровки	
	 freq  F@    FreqNum  n ! 
	n @ 1 - take_freq_in_number     \ FDUP F. freq  F@  F. CR
	freq  F@  deltaFreq 
	IF \ разные частоты
		 n @ 1 + take_freq_in_number    freq F!
	ELSE \ одинаковые частоты - требуется дополнительная проверка
		LastFreq F@  LastFreq2 F@ 
		\ ." last=" LastFreq F@  F. LastFreq2 F@ F. CR 
		 deltaFreq  \ 2 раза подали чатоту?
		IF \ разные 
			 n @ 1 + take_freq_in_number    freq F!
		THEN
	THEN
	freq F@
\   CR
;

 : PredFreq ( freq_old -- freq_new ) \ перебор вниз!
	FreqNum       1 - take_freq_in_number    \  CR
 ;

: TakeData \ ( freq  num  -- data )
	|| D:  num   D: n F: freq   ||
	num ! \ номер точки 
	freq F!  0 n !
	num_datas @ \ количество точек
	0  
	DO \ прошли по всей матрице
		I  take_freq_in_number    freq F@  F<  IF I  n !  THEN 
	LOOP \ нашли номер точки
	LastFreq   F@  freq F@ deltaFreq  \ разные частоты
	IF  
		n @  num_datas @ 1- = IF num_datas @  2 -  n ! THEN	
		\ линейная инретполяция
		  \ (у1-1024 у2)/(х1-х2)*х1 +у1
		  n @ 1+ num @ take_data_in_number  n @ num @ take_data_in_number  F-  \ (уk-уn)  
		  n @ 1+  take_freq_in_number  n @  take_freq_in_number  F-  \ (хk-хn)
		 F/  ( ***/***)
		 freq F@
		 n @  take_freq_in_number    \ (***) *х1
		  F- F* \ (***) *х1
		   \  n 1+ ПолучитьАнтенныйФакторПоНомеру    FSWAP F- \ (***) + у1
		  n @ num @ take_data_in_number     F+ 
		\ CR n @ . num_datas @ . num @ .  F.
	ELSE	
		n @ 2 + num @ take_data_in_number        
	THEN
 ;


 : LoadData 
	 num_datas @ 1  adr_data_in_number F!
	 num_datas @ 0  adr_data_in_number F!
	 num_datas @ 1 + num_datas   !
;

\ : :SetData  datas ! ;
 :  LoadDatas:  \  (  row col--) забронировать 
   (   adr_data,   n_Data )
	 SELF TO tekdata 
	 num_datas_in_string ! 0  num_datas ! \ :SetData  
	 num_datas_in_string @ FLOATS *  CELL + ALLOCATE THROW   datas !
 
;
 : SeeDatas \ { adr \ --  }
	 \ || D: adr || adr !
	\ num_datas @  . num_datas_in_string @  . CR
	CR
	num_datas @ 
	DUP 1 > 
	IF
		0 
		DO
\			I take_freq_in_number F.
			num_datas_in_string @  
			DUP 1 >
			IF
				1 
				DO
					J I take_data_in_number F. 
				LOOP
				CR
			THEN
		LOOP 
	ELSE
		." num_datas = 0 " CR 
	THEN
;



 : LoadData: ( num -- )
	\ num_datas @ . num_datas_in_string @ .  ." |"
	 num_datas_in_string @  0 
	 DO   
		 NextWord  \ 2DUP TYPE SPACE
		  STR>S  S>FLOAT  DROP \ F.
		 num_datas @ I adr_data_in_number F!
	LOOP
	\ num_datas @ 1  adr_data_in_number F!
	\ num_datas @ 0  adr_data_in_number F!
	 num_datas @ 1 + num_datas   !
;

: dispose 
	datas @ FREE THROW  
	0 num_datas !
	
;

: SaveData  \ s-filename
|| D: file ||

	outFileCreate file !
	num_datas @ 10 + file @ DtoFile 
	num_datas_in_string @	file @ DtoFile 
	" LoadDatas: "	file @ StoFile 
	file @ CRtoFile 
	CR
	num_datas @ 
	0 
	DO
		" LoadData:  "	file @ StoFile 
		I take_freq_in_number  \ FDUP
		  file @ FtoFile \   F.
		num_datas_in_string @ 1 
		DO
			J I take_data_in_number  FDUP file @ FtoFile  F.
		LOOP
	file @ CRtoFile 
	\		CR
	LOOP 
	file @ outFileClose 
;

 : SaveFile  \  сохранить табличку в файл  
 \ s-filename
|| D: file ||
." SaveFile... "
	outFileCreate file !
	CR
	num_datas @ 
	0 
	DO
		I take_freq_in_number   \ FDUP  
		file @ FtoFile   \  F.
		num_datas_in_string @ 1 
		DO
			J I take_data_in_number  FDUP file @ FtoFile  F.
		LOOP
	file @ CRtoFile 
	\		CR
	LOOP 
	file @ outFileClose 
." ... SaveFile "
;
: SaveFile DROP CR ." SaveFile" CR ;

: LoadFile  (  name     -- ) \ загрузить табличку из файла "name"  с кличеством колонок "col"
|| D: name   D: str  D: file  D: len    D: col D: Icorrect D: numrow ||
 \  col !
  name ! 
 0 numrow !
   1024 ALLOCATE  THROW  str !

\ + 1. считаем кол-во данных в файле  зная кол-во столбцов   num_datas_in_string    NextWord 
\ 2. выделяем соостественно памяти
\ 3. читаем поочереди цифры, и пишем их по порядку в табличку.
 name @ STR@ R/O   OPEN-FILE   
	  IF ." file not open"
	 DROP
	  ELSE
	   file ! 
	  0 num_datas ! 
 BEGIN	   
	str @ 1023    file @ READ-LINE  
	THROW DROP len !
	numrow  @ 0 = IF str @ len @ STR>S NumWordsString  numrow ! THEN
 
\	str @ len @ TYPE  CR
	num_datas @ 1 + num_datas ! 
len @ 0 = 
UNTIL
	num_datas @ 1 - num_datas ! 
\ в последней строке считаем  кол-во слов

\ ." num=" numrow @ . 
\	str @  
\ STR>S NumWordsString 
\ 5 
numrow @  1 +  DUP max_datas ! col !


 file @ CLOSE-FILE THROW
THEN 
CR name @ STR@ TYPE ."  num_datas = " num_datas @ .  ." numrow = " numrow @  . CR

SELF TO tekdata 
col @ 	 num_datas_in_string !   \ :SetData  

 \  datas @ dispose
   
num_datas @ col @   * FLOATS   CELL +     ALLOCATE THROW   datas !

num_datas @ 0 > 
IF
   name @ STR@ R/O   OPEN-FILE   
   IF ." file not open" DROP
   ELSE  
    file ! 

	num_datas @ 0  
	DO	
	0 Icorrect ! 
		 str @ 1023    file @ READ-LINE  
		THROW DROP len !
		\ I . str @ len @ TYPE  CR
		num_datas_in_string @ 0
		DO  I   Icorrect @  - \ .
		   str @ len @ STR>S I  N_S_PickUpWord \ STYPE ."  "
		   S>FLOAT  0 =
		   J I Icorrect @ -  adr_data_in_number F!		     
		   IF
			Icorrect @ 1 + Icorrect !
		   THEN
		   
		LOOP 
		\ CR
	LOOP
     file @ CLOSE-FILE THROW
    THEN   
ELSE
		     0e 0 0  adr_data_in_number F!
THEN

 str @ FREE  DROP
;



;CLASS

: LoadDatas: ROT ^ LoadDatas: ; ( obj line col -- )
: LoadData tekdata  ^ LoadData ;  ( data1 .. dataN -- )
: LoadData: tekdata  ^ LoadData: ;   ( data1 .. dataN -- )
: SeeDatas   ^ SeeDatas ;
: :LoadFile ^ LoadFile ;


 \EOF

 tabl_kalibr NEW kalibrovka 

   " ~disa/1.kal"   kalibrovka  LoadFile
   CR CR
kalibrovka SeeDatas

\EOF
 tabl_kalibr NEW k12 
\ kalibrovka  .
\  kalibrovka  see tabl_kalibr NEW kalibrovka 

\ 0 , HERE  1024  ALLOT VALUE kalibrovka

CR
10 2 kalibrovka   LoadDatas:
 80.000e6	-20.6E	LoadData
 300.000e6	-9.9E	LoadData
600.259e6	-14.4E	LoadData
1.000e9        -10.1E	LoadData
1.000e9        -1.1E	LoadData
2.000e9        -2.1E	LoadData
3.000e9        -3.1E	LoadData
4.000e9        -4.1E	LoadData

\ SaveFreq 

\ EOF
kalibrovka SeeDatas
CR
  100.000e6 1 kalibrovka TakeData  F.
  CR
  1000.000e6 1 kalibrovka TakeData  F.
  CR
  1000.000e6 1 kalibrovka TakeData  F.
  CR
  1e9 kalibrovka SaveFreq
  1000.000e6 1 kalibrovka TakeData  F.
  CR
  
\ EOF
\  0 , HERE  1024  ALLOT VALUE k12
10 2 k12  LoadDatas:
 1.000e6	 1.E	LoadData
 2.000e6	 2.E	LoadData
 3.000e6	 3.e	LoadData
 4.000e6	 4.E	LoadData
 5.000e6	 5.E	LoadData
 6.000e6	 6.E	LoadData
 7.000e6	 7.E	LoadData
k12 SeeDatas

: z 
4.5000e6	1 k12 TakeData  F.
 0.000e6		1 k12 TakeData F. 
 8.000e6		1 k12 TakeData  F. 
; 
CR

tabl_kalibr NEW k0 

30 3 k0  LoadDatas:
 LoadData:   1.000e6  1.2E	10.5E
 LoadData:   2.000e6  3.E	10.6E
 LoadData:   3.000e6  4.E	10.7E
 k0 SeeDatas
  1.000e6 1 k0 TakeData  F.
  