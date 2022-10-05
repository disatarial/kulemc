\ управление настройкой приборов
STARTLOG
 REQUIRE CAPI: lib/win/api-call/capi.f
 REQUIRE gtk_init  /emctest/gtk-api.spf
 REQUIRE  CASE  lib/ext/case.f
 REQUIRE WildCMP-U ~pinka/lib/mask.f \ \ сравнение строки и маски, для  проверки ответа оборудования
 REQUIRE  objLocalsSupport ~day/hype3/locals.f \ локальные переменные
 REQUIRE  tabl_kalibr  ~disa/kalibr_hype.f      \ объекты
 REQUIRE  dBuV->V  ~disa/algoritm.f             \ различные алгоритмы
 REQUIRE FIND-FILES ~ac\FINDFILE.F         \ поиск файлов
 REQUIRE AddNode ~ac\STR_LIST.F            \ список
 REQUIRE  STR@ ~ac\str5.f                    \ работа с динамическими строками
 
 HERE  0 , 64 ALLOT VALUE Directory  \ путь к методам программы
VARIABLE filefilter_kal

  
: LOAD_TO_BUFER { s-adr adr \ u   -- }
s-adr STR@  ." LOAD_TO_BUFER "  DUP . ." : " TYPE CR
s-adr STR@  DUP 255 > IF DROP 255 THEN -> u
adr  1+ u CMOVE 
s-adr STRFREE
u adr  C!

;

VARIABLE num_data \ номер последних/текущих данных в списке  gtk_tree... только для передачи внутри граф. интерфейса
VARIABLE LoadPribor \ загруженый прибор

 0 , HERE 256 ALLOT  VALUE ERROR_PROG_BUFER \ буфер ошибок
VARIABLE  ERROR_PROG 

: LOAD_TO_ERR_BUFER { s-adr adr \ u    -- }
s-adr STR@ NIP  adr  C@ + 255 > IF 255  adr  C@ - ELSE  s-adr STR@ NIP  THEN -> u
 s-adr STR@ DROP  adr  1 + adr  C@ +  u CMOVE  
 s-adr STRFREE
 adr  C@   u + adr  C!
;
: TYPE_BUFER { bufer } 
bufer  1+ 
bufer  C@   DUP 0 > IF TYPE ELSE 2DROP ."  no info in buffer "  THEN 
;

: CLEAR_ERROR_BUFER 255 0 DO 0 ERROR_PROG_BUFER   I + C!  LOOP ;
: TYPE_ERROR_PROG_BUFER  ERROR_PROG_BUFER   TYPE_BUFER ;	
: TO_ERROR_PROG_BUFER    ERROR_PROG_BUFER  LOAD_TO_ERR_BUFER ;  ( s-adr  ) \ ошибку в буфер

\ отработка ошибки
: :ERROR  { s-adr-err n-err  } 
   s-adr-err  LOAD_TO_ERR_BUFER  n-err ERROR_PROG ! TYPE_ERROR_PROG_BUFER   -1 ;


REQUIRE PriborPassport priborpassport.f

\ VECT Save_PriborPassport  \ процедура сохранения данных прибора 
\ VECT  PriborPassportSeeOne \ \ \ подготовить в выводу описание переменной из настроек
\ VECT SaveInterface	   \ процедура сохранения информации об интерфейсах
\ VECT FileInterface         \ команда показа файла интерфейса

\ нулевые действия
\ :NONAME DROP 0 ;  TO PriborPassportSeeOne
\ :NONAME DROP 0 ;  TO PriborinterfaceSeeOne
\ :NONAME STRFREE ;  TO SaveInterface
\ :NONAME S" " DUP  0 SWAP  C!  ;  TO  FileInterface

\ оболочка для пользователя
VARIABLE pargv
VARIABLE pargs
VARIABLE window
VARIABLE builder
VARIABLE error  \ сюда скидывать номер ошибки 

VARIABLE builder_pribor
VARIABLE win_pribor
VARIABLE buttonClosePribor
\ VARIABLE liststore_interface
\ VARIABLE treeview_interface
VARIABLE treeview_param_prib
VARIABLE liststore_param_prib
VARIABLE iter_store_param_prib 
VARIABLE  buttonSavePribor


VARIABLE  filefilter_prib
VARIABLE  filechooserbutton_pribor 
\ VARIABLE  filechooserbuttoninterface
\ VARIABLE  filefilter_interface

 
\ диалог ввода цифр и файлов в методы  
VARIABLE dialog 
VARIABLE button_norma
VARIABLE button_error 
VARIABLE dialog_entry
VARIABLE dialog_label
VARIABLE dialog_filechooserbutton 

  
VARIABLE  button_proverka
VARIABLE  entry_proverka
  
  
\ различные итераторвы
\ 0 , HERE  64 ALLOT  VALUE iter_store_interface
 0 , HERE  64 ALLOT  VALUE iter_store_pribor
\ 0 , HERE  64 ALLOT  VALUE iter_n
\ 0 , HERE  64 ALLOT  VALUE iter_k


 : FindDataList { data-adr  flag \ s -- s }
   flag 1 = IF data-adr  @ >NUM  STR>S -> s THEN
   flag 2 = IF data-adr F@ >FNUM STR>S -> s THEN
   flag 2 > flag 6 < AND IF data-adr 1+ data-adr C@ STR>S -> s THEN
   flag 5 > flag 1 < OR IF "  закончено" -> s THEN
s ;

: Refresh_param_prib_list { \ adr u I flag  s  data-adr }
 liststore_param_prib  @ 1 gtk_list_store_clear	 DROP
0 -> I
 BEGIN
   I PriborPassportSeeOne  ."  PriborPassportSeeOne: " DUP . ." " 
 DUP  0 >  
 WHILE
      -> u -> adr   -> flag      -> data-adr  
    ." Refresh_param_prib_list "  adr u TYPE ." -> " flag . CR
	I iter_store_pribor  liststore_param_prib  @  3 gtk_list_store_insert DROP
 	data-adr   flag FindDataList  -> s
   -1 I 0 adr u STR>S DUP >R STR@ DROP 1  s DUP >R STR@ DROP 2   iter_store_pribor liststore_param_prib  @ 9 gtk_list_store_set DROP R> STRFREE  R> STRFREE  
   I 1 + -> I
."  I: " I . ."  " CR
		flag 1 =  \ целые
		IF 
			data-adr  @ >NUM  STR>S -> s 
		THEN
		flag 2 =  \ действительное
		IF 
			data-adr F@ >FNUM STR>S -> s 
		THEN
		flag 2 > flag 6 < AND 
		IF  \ строчки
			data-adr 1+ data-adr C@ STR>S -> s 
		THEN
		
\		flag 6 = 
\		IF \ частота с множителем 
\			data-adr F@    ->degree F/ 
\			>FNUM STR>S -> s 
\		THEN

		flag 5 > flag 1 < OR 
		IF 
			"  закончено" -> s 
		THEN
 \		-1 I 0 adr u STR>S DUP >R STR@ DROP 1  s DUP >R STR@ DROP 2   iter_store_text liststore_metod_text  @ 9 gtk_list_store_set DROP R> STRFREE  R> STRFREE  
		 s STYPE CR
		 \ s STRFREE 
\ PriborPassport_info 
REPEAT
DEPTH .
DROP
; 

:NONAME 
\  0 DisableButon !
	win_pribor @ 1 gtk_widget_destroy DROP  BYE
	0 ;  1 CELLS  CALLBACK: on_pribor_destroy   

:NONAME  
DEPTH . ." : "  .S CR
	win_pribor @ 1 gtk_widget_destroy DROP    
	0 ;  1 CELLS  CALLBACK: buttonClosePribor_click 
 

:NONAME  { \ s s2  s3 flag file  str len  num }

-1 -> flag
"" -> s "" -> s2
." DEPTH =" DEPTH . ." : " .S   ."  filechooserbutton_pribor_open  "  

\ грузим имя настроек
   filechooserbutton_pribor  @ 1 gtk_file_chooser_get_filename    -> file 
   ."  gtk_file_chooser_get_filename = " file .  ." DEPTH =" .S 	CR

 file	0=
 IF 0   -> flag  
 THEN
 
." DEPTH  include =" .S  ." flag=" flag .  CR
 flag	
 IF   
\ грузим файл прибора 
	s STRFREE
	file ASCIIZ> STR>S   -> s  DEPTH . 
	s STR@   ." INCLUDE FILE: "   TYPE CR
s STR@  -> len -> str
len -> num 
   0 > IF
	CR len . CR
		len  0  DO

			str I + C@ 47 =
			str I + C@ 92 = 
			OR
			IF I -> num THEN
		LOOP
	ELSE 0 -> flag  THEN
	
 CR num CR str num TYPE CR
"" -> s3
 str num  1 + s3  STR+ 
S" haracter.spf" s3 STR+ 
S" file = " TYPE s3 STR@ TYPE CR
	s3 STR@   INCLUDE-PROBE   .S  
	 -> file
	file  
	IF	
		" error ineterface generator " TO_ERROR_PROG_BUFER   
		0 -> flag 
	ELSE -> file
	\ -1 -> flag
	THEN
 THEN
 
 ." DEPTH OBJ =" DEPTH . ." : " .S  ." flag=" flag .  CR
\ flag	
\ IF 
\	file NewObj  LoadPribor !   \ подключили для проверки
\	." filechooserbutton_pribor_open=" s STR@ TYPE  ."  " .S CR
\ THEN
 \ грузим настройки

\ THEN
 s STRFREE
 s2 STRFREE
 s3 STRFREE

\  THEN \ IF EXIT THEN
  ." DEPTH=" DEPTH . ." : "   .S   CR 
  Refresh_param_prib_list
\ DROP

\  PriborPassport_info	interface 1+ 
\ FileInterface   filechooserbuttoninterface  @  2 gtk_file_chooser_set_filename  .
 \ filechooserbuttoninterface_open
  ." end _pribor_open DEPTH="  .S   CR 
	window @  0 ;  1 CELLS  CALLBACK: filechooserbutton_pribor_open  

	
 :NONAME  ." treeview_param_prib_click" CR 
  {  column path tree_view \ model  flag  adr u  tekFile }
." TreeView_start_metod_click"  CR
dialog @  1 gtk_widget_show DROP
\ выделенная строчка 
  tree_view  1 gtk_tree_view_get_model   -> model 
  path iter_store_pribor  model 3   gtk_tree_model_get_iter DROP \ (model, &iter, path_string)
  iter_store_pribor model 2 gtk_tree_model_get_string_from_iter    ASCIIZ> STR>S   \ STYPE ."  "
   S>FLOAT 
\ Временно 
 IF F>D D>S  num_data ! \ запомнить номер строчки с данными
	num_data @ PriborPassportSeeOne \ адрес данных,тип данных,  название данных   длинна названия
	-> u -> adr  -> flag
	adr u STR>S DUP >R  STR@ DROP dialog_label @ 2 gtk_label_set_text DROP R> STRFREE
	flag 1 = IF @  >NUM  STR>S   THEN	 \ целое
	flag 2 = IF F@ >FNUM  STR>S  THEN      \ действительное
	flag 3 = 
\	flag 5 = OR 
	flag 4 = OR
	IF DUP 1+ SWAP C@ STR>S  THEN \ просто текст
	flag 5 = IF  			\ имя файла калибровки
		DUP 1+ SWAP C@ STR>S 
		Directory   ASCIIZ>  "" DUP -> tekFile  STR+   " /default.kal" tekFile  S+ tekFile   STR@  ." Directory   " TYPE CR 
		tekFile    >R  R@ STR@  DROP dialog_filechooserbutton  @ 2 gtk_file_chooser_set_uri  R> STRFREE  ." dialog_filechooserbutton =" . CR 	
		filefilter_kal @ dialog_filechooserbutton   @ 2 gtk_file_chooser_add_filter DROP
		\ DUP STR@ DROP dialog_filechooserbutton @ 2 gtk_file_chooser_set_filename DROP    		
		THEN
\	flag 5 = IF  			\ имя файла прибора
\		DUP 1+ SWAP C@ STR>S 
\		" ./prib" -> tekFile    " /default.prib" tekFile  S+ tekFile   STR@ ." Directory   " TYPE CR 
\		tekFile    >R  R@ STR@  DROP dialog_filechooserbutton  @ 2 gtk_file_chooser_set_uri  R> STRFREE  ." dialog_filechooserbutton =" . CR 	
\		filefilter_prib @ dialog_filechooserbutton   @ 2 gtk_file_chooser_add_filter DROP
\	\	 DUP STR@ DROP dialog_filechooserbutton @ 2 gtk_file_chooser_set_filename DROP    		
\		THEN
	flag 5 > flag 1 < OR IF " ERROR " THEN
	DUP >R  STR@ DROP dialog_entry    @ 2 gtk_entry_set_text DROP R> STRFREE
THEN
column path tree_view 	window @   ;  3 CELLS  CALLBACK:  treeview_param_prib_click 
	 
:NONAME  { \ s  s2 int save_file  err }
\ DEPTH . 
   filechooserbutton_pribor  @ 1 gtk_file_chooser_get_filename    DUP  ."  filechooserbutton_pribor= " . CR
   DUP 0 = IF DROP S"   " DROP DUP 0 SWAP 1 + C! THEN  ASCIIZ>  STR>S  -> s   \ " sava.txt"  

 \ DEPTH . 
\     filechooserbuttoninterface  @ 1 gtk_file_chooser_get_filename    DUP  ."  filechooserbuttoninterface= " . CR
\   DUP 0 = IF DROP S"   " DROP DUP 0 SWAP 1 + C! THEN ASCIIZ> STR>S  -> int   \  interface  
   
\ DEPTH . 
s STR@ ?STR_FILE  \ int STR@ ?STR_FILE
  \ AND 
  IF  \ оба файла в наличии
	s STR@ 12 - STR>S -> s2  \ удалили название файла
	s STRFREE
	s2 STR@ STR>S -> s  \ оставили только путь к каталогу
	" \haracter.spf" s2 S+   \ встаивли новое
	."  savefile= " s2 STR@ TYPE CR
	\ " tst.txt"
	 s2 
	  outFileCreate ->  save_file
	save_file  Save_PriborPassport
	save_file outFileClose
	
 	\ s SaveInterface \ после использования s -удаляется автоматически
	"" -> s		\ пвосстанавливаем s для удаления после ИФа	
\ sadr STR@  ."  "  TYPE ."  " 
\ s2 STRFREE
." ...file-save. " CR
 ELSE
 ." ...file not save. " CR
 THEN
 \ int STRFREE
 s STRFREE
\  DEPTH .
1000 PAUSE
	window @  ;  1 CELLS  CALLBACK: buttonSavePribor_click  
 
 
:NONAME   { \ flag  adr_str  adr u tekFile }
  num_data @ PriborPassportSeeOne \ адрес данных,тип данных,  название данных   длинна названия
  2DROP -> flag  -> adr_str  	
\ выясняем какой тип  данных 
." flag: " flag . CR 
 flag  1 =  flag  2 =  OR \ действительное или  целое
	IF  dialog_entry  @ 1 gtk_entry_get_text_length   DUP 0 > 
		IF 
			dialog_entry  @ 1 gtk_entry_get_text    -> adr  -> u \ adr u 	
			adr u  ."  NUMBER: "  TYPE ."  " 			
			adr u  STR>FLOAT    FDUP F. CR
		\	1000 PAUSE
			IF
				flag  2 =  IF	 adr_str F!  ELSE  F>D D>S  adr_str ! THEN \ действительное или целое
			ELSE FDROP -1 -> flag
			THEN 
\		CR DEPTH .   FDEPTH . CR
		ELSE DROP -1 -> flag 
\				CR  DEPTH . FDEPTH . CR 1000 PAUSE

		THEN
	THEN
	flag  3 =  \ строка,название
	flag  4 =  OR \ строка,название
\	flag  5 =  OR \ строка,название
	
	IF   
	 dialog_entry  @ 1 gtk_entry_get_text_length   DUP 0 > 
		 IF 
			dialog_entry  @ 1 gtk_entry_get_text    -> adr  -> u
			adr u  ."  string: "  TYPE ."  " 
			adr u STR>S adr_str LOAD_TO_BUFER	
		ELSE  DROP -1 -> flag 
		THEN
		
	THEN
	flag  5 =  \ файл 
	IF
		filefilter_kal @ dialog_filechooserbutton   @ 2 gtk_file_chooser_remove_filter DROP
	
		 dialog_filechooserbutton @ 1 gtk_file_chooser_get_filename \  взяли имя
		DUP 
		IF ASCIIZ> 2DUP ?STR_FILE			\ проверили наличие файла
			IF  STR>S adr_str LOAD_TO_BUFER		\
			ELSE  -1 -> flag 
			THEN  
		ELSE -1 -> flag 
		THEN
	THEN
(	flag  5 =  \ файл оборудования
	IF
			filefilter_prib @ dialog_filechooserbutton   @ 2 gtk_file_chooser_remove_filter DROP

		 dialog_filechooserbutton @ 1 gtk_file_chooser_get_filename \  взяли имя
		DUP 
		IF ASCIIZ> 2DUP ?STR_FILE			\ проверили наличие файла
			IF  STR>S adr_str LOAD_TO_BUFER		\
			ELSE  -1 -> flag 
			THEN  
		ELSE -1 -> flag 
		THEN
	THEN

 )
	 dialog   @ 1 gtk_widget_hide DROP 
	 Refresh_param_prib_list 
	 \ THEN 
dialog   @ 
;  1 CELLS  CALLBACK: button_norma_click
 
 :NONAME 	dialog @  1 gtk_widget_hide DROP  
 0 ;  1 CELLS  CALLBACK: button_error_click
 
 
\  :NONAME   { \ s   }
\ ."  filechooserbuttoninterface_open  " 
\ грузим имя настроек
\   filechooserbuttoninterface  @ 1 gtk_file_chooser_get_filename    DUP  ."  filechooserbuttoninterface_open = " . CR
\ DEPTH .
\  DUP  IF \  DEPTH .
\ грузим файл прибора настройки
\	ASCIIZ> STR>S   -> s   DEPTH . 
\	s STR@  INCLUDE-PROBE   DEPTH . 
\ ." filechooserbuttoninterface_open2=" s STR@ TYPE  DEPTH . CR
\		IF     " Error: load pribor-file problem  " STYPE CR \  error_metod_file :ERROR    
\		ELSE  
\		s SaveInterface 
\		"" -> s
\		THEN
\ грузим настройки
\	s STR@ 12 - STR>S -> s2 
\    " \haracter.spf"  s2  	  S+
\ ." filechooserbutton_haracter_pribor_open=" s2 STR@ TYPE CR
\  s2 STR@ INCLUDE-PROBE 	 
\		IF     " Error: load haracter-pribor problem  "  \  error_metod_file :ERROR     
	\	THEN
\	 s STRFREE
 \ s2 STRFREE
\  THEN \ IF EXIT THEN
\  ." DEPTH=" DEPTH .   CR 
  

\  Refresh_param_prib_list
\ DROP
 
\  window @  ;  1 CELLS  CALLBACK: filechooserbuttoninterface_open  
 
 :NONAME  
 ." button_proverka_click "  CR
 \  metod-info  file_generator_buf	LoadPribor @ ^ Start IF " generator not found " TO_ERROR_PROG_BUFER  -1 THROW THEN

	window @    ;  1 CELLS  CALLBACK: button_proverka_click


: Startpribor
 pargv pargs  2  gtk_init  DROP \ 2DROP 
 
  0 gtk_builder_new   builder_pribor !
   error  " pribor.glade"  >R R@ STR@  DROP  builder_pribor @ 3 gtk_builder_add_from_file DROP   R> STRFREE \ 2DROP 
  " pribor"  >R R@ STR@  DROP builder_pribor @ 2 gtk_builder_get_object win_pribor !  R> STRFREE \ 2DROP
  win_pribor @  1 gtk_widget_show DROP \ DROP

   \ ДЕЙСТВО ЗАКРЫТИЕ ПРОГРАММЫ
   " destroy"  >R 0 0 0  ['] on_pribor_destroy  R@ STR@ DROP win_pribor @ 6 g_signal_connect_data   R> STRFREE  DROP \ 2DROP 2DROP 2DROP

 " buttonClosePribor" >R  R@ STR@  DROP builder_pribor   @ 2 gtk_builder_get_object buttonClosePribor  !    R> STRFREE \ 2DROP
  " clicked"  >R 0 0 0  ['] buttonClosePribor_click R@ STR@ DROP buttonClosePribor @ 6 g_signal_connect_data   R> STRFREE  DROP \ 2DROP 2DROP 2DROP
 
 " buttonSavePribor" >R  R@ STR@  DROP builder_pribor   @ 2 gtk_builder_get_object buttonSavePribor !    R> STRFREE \ 2DROP
  " clicked"  >R 0 0 0  ['] buttonSavePribor_click R@ STR@ DROP buttonSavePribor @ 6 g_signal_connect_data   R> STRFREE  DROP \ 2DROP 2DROP 2DROP
  
  

  
   " button_proverka" >R  R@ STR@  DROP builder_pribor   @ 2 gtk_builder_get_object button_proverka  !    R> STRFREE \ 2DROP

  " clicked"  >R 0 0 0  ['] button_proverka_click R@ STR@ DROP button_proverka @ 6 g_signal_connect_data   R> STRFREE  DROP \ 2DROP 2DROP 2DROP
   " entry_proverka" >R  R@ STR@  DROP builder_pribor   @ 2 gtk_builder_get_object entry_proverka  !    R> STRFREE \ 2DROP

  
  \ указатель для загрузки и  сохранении , устанавливаем фильтр для приборов
 " filechooserbutton_pribor" >R  R@ STR@  DROP builder_pribor   @  2 gtk_builder_get_object filechooserbutton_pribor !    R> STRFREE \ 2DROP
 " filefilter_prib" >R  R@ STR@  DROP builder_pribor   @  2 gtk_builder_get_object filefilter_prib !    R> STRFREE \ 2DROP
 filefilter_prib @ filechooserbutton_pribor  @ 2 gtk_file_chooser_add_filter DROP
 
   " ./prib/" >R  R@ STR@  DROP filechooserbutton_pribor  @ 2 gtk_file_chooser_set_current_folder   R> STRFREE   ." filechooserbutton_pribor =" . CR 
 " file-set"    >R 0 0 0  ['] filechooserbutton_pribor_open  R@ STR@ DROP filechooserbutton_pribor  @ 6 g_signal_connect_data   R> STRFREE  DROP \ 2DROP 2DROP 2DROP
    

  \ указатель для загрузки , устанавливаем фильтр для интерфейсов
\ " filechooserbuttoninterface" >R  R@ STR@  DROP builder_pribor   @  2 gtk_builder_get_object filechooserbuttoninterface !    R> STRFREE \ 2DROP
\ " filefilter_interface" >R  R@ STR@  DROP builder_pribor   @  2 gtk_builder_get_object filefilter_interface !    R> STRFREE \ 2DROP
\  filefilter_interface @ filechooserbuttoninterface @ 2 gtk_file_chooser_add_filter DROP
\ " ./interface/" >R  R@ STR@  DROP filechooserbuttoninterface  @ 2 gtk_file_chooser_set_current_folder   R> STRFREE  ." filefilter_interface =" . CR 

 \ " file-set"    >R 0 0 0  ['] filechooserbuttoninterface_open  R@ STR@ DROP filechooserbuttoninterface @ 6 g_signal_connect_data   R> STRFREE  DROP \ 2DROP 2DROP 2DROP



  \ готовим окошко под параметры оборудования
    " treeview_param_prib"  >R R@ STR@ DROP builder_pribor    @ 2 gtk_builder_get_object treeview_param_prib  ! R> STRFREE
    " liststore_param_prib" >R R@ STR@ DROP builder_pribor   @ 2 gtk_builder_get_object liststore_param_prib ! R> STRFREE  
  \  iter_store_param_prib liststore_param_prib  @ 2 gtk_list_store_append DROP
\    liststore_param_prib  @ 1 gtk_list_store_clear	 DROP
   " row-activated"    >R 0 0 0  ['] treeview_param_prib_click R@ STR@ DROP treeview_param_prib @ 6 g_signal_connect_data   R> STRFREE  DROP \ 2DROP 2DROP 2DROP


  \ вставляем интерфейсы
 \   " treeview_interface"  >R R@ STR@ DROP builder_pribor @ 2 gtk_builder_get_object treeview_interface  ! R> STRFREE
 \   " liststore_interface" >R R@ STR@ DROP builder_pribor @ 2 gtk_builder_get_object liststore_interface ! R> STRFREE  
\    iter_store_interface liststore_interface  @ 2 gtk_list_store_append DROP
 \   liststore_interface  @ 1 gtk_list_store_clear	 DROP
 \  " row-activated"    >R 0 0 0  ['] treeview_interface_click R@ STR@ DROP treeview_interface @ 6 g_signal_connect_data   R> STRFREE  DROP \ 2DROP 2DROP 2DROP

 

\ 1 ['] timer_pribor  1000 3 g_timeout_add DROP


\ поднятие диалога выбора  вот тут проблемма что если удалять и включать. то  втором и последующих включениях появляетя голое окно без кнопочек.
 " dialog_label" >R  R@ STR@  DROP builder_pribor @ 2 gtk_builder_get_object dialog_label !    R> STRFREE \ изменяемая надпись
 " dialog"  DUP >R STR@  DROP builder_pribor @ 2 gtk_builder_get_object  dialog !  R> STRFREE \ 2DROP
 " button_norma" >R  R@ STR@  DROP builder_pribor @  2 gtk_builder_get_object button_norma !    R> STRFREE \ 2DROP
 " clicked"  >R 0 0 0  ['] button_norma_click   R@ STR@ DROP button_norma @ 6 g_signal_connect_data   R> STRFREE  DROP \ 2DROP 2DROP 2DROP
 " button_error" >R  R@ STR@  DROP builder_pribor @  2 gtk_builder_get_object button_error !    R> STRFREE \ 2DROP
 " clicked"  >R 0 0 0  ['] button_error_click   R@ STR@ DROP button_error @ 6 g_signal_connect_data   R> STRFREE  DROP \ 2DROP 2DROP 2DROP
 " dialog_entry" >R  R@ STR@  DROP builder_pribor @ 2 gtk_builder_get_object dialog_entry !    R> STRFREE \ 2DROP
 " dialog_filechooserbutton"  >R  R@ STR@  DROP builder_pribor @  2 gtk_builder_get_object dialog_filechooserbutton !    R> STRFREE \ 2DROP
   dialog @  1 gtk_widget_hide DROP 
 \ dialog  @  1 gtk_widget_show DROP \ DROP
 
\ устанавливаем фильтр для настроек
\ filefilter_nast @ filechooserbutton_file_nastr   @ 2 gtk_file_chooser_add_filter DROP
 0 gtk_main  DROP 
;


0 VALUE runthread

: start
 ['] Startpribor TASK TO runthread
  runthread START
; 

start 
  
    TRUE TO ?GUI
 \    ' CECONSOLE MAINX !
 ' start MAINX !
         S" pribor.exe"  SAVE
   \  BYE
 
 
 
\ : T S" .\metod\*.*" ['] addListMetod FIND-FILES ; T

\ start

: ssf { \ save_file s -- }
	S" tst.txt" W/O CREATE-FILE-SHARED IF   ." file not created" CR  DROP 0 THEN

\	s outFileCreate 
->  save_file
\	s STRFREE
	save_file  Save_PriborPassport
\	save_file  SaveInterface
	save_file outFileClose
;


\ flag IF
\		s STR@ 12 - STR>S -> s2 
\		" \haracter.spf"  s2  	  S+
\		 ." filechooserbutton_haracter_pribor_open=" s2 STR@ TYPE   DEPTH . CR
\		s2 STR@ INCLUDE-PROBE 	 
\		IF     " Error: load haracter-pribor problem  "  :ERROR     
\		 0 -> flag
\ 		THEN