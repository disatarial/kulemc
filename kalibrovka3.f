\ управление настройкой приборов
STARTLOG
 REQUIRE CAPI: lib/win/api-call/capi.f
 REQUIRE gtk_init  gtk-api.spf
 REQUIRE  CASE  lib/ext/case.f
 REQUIRE WildCMP-U ~pinka/lib/mask.f \ \ сравнение строки и маски, для  проверки ответа оборудования
 REQUIRE  objLocalsSupport ~day/hype3/locals.f \ локальные переменные
 REQUIRE  tabl_kalibr  ~disa/kalibr_hype.f      \ объекты
 REQUIRE  dBuV->V  ~disa/algoritm.f             \ различные алгоритмы
 REQUIRE FIND-FILES ~ac\FINDFILE.F         \ поиск файлов
 REQUIRE AddNode ~ac\STR_LIST.F            \ список
 REQUIRE  STR@ ~ac\str5.f                    \ работа с динамическими строками
 REQUIRE  F. ~disa\dopoln.f




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



VARIABLE num_data \ номер последних/текущих данных в списке  gtk_tree... только для передачи внутри граф. интерфейса
 VARIABLE  kalibrovka   \ загруженый  калибровка

: createtablkalibr
	tabl_kalibr NewObj   kalibrovka   !
 ;
 
VARIABLE num  \ номер выделенной строки
0 , HERE  512 ALLOT  VALUE KalFeleName
 

\ оболочка для пользователя
VARIABLE pargv
VARIABLE pargs
VARIABLE window
VARIABLE builder
VARIABLE error  \ сюда скидывать номер ошибки 

VARIABLE builder_pribor
VARIABLE win_pribor


VARIABLE buttonClosePribor
VARIABLE treeview_param_kal
VARIABLE liststore_param_kal
 VARIABLE  buttonSavePribor


VARIABLE  filefilter_kal
VARIABLE  filechooserbutton_kal 
 
 
\ диалог ввода цифр и файлов в методы  
VARIABLE dialog 
VARIABLE button_norma
VARIABLE button_error 

VARIABLE  dialog_entry_freq
VARIABLE  dialog_entry_data
VARIABLE  dialog_entry_begindata
VARIABLE  button_norma
VARIABLE  button_error



VARIABLE  buttonAdd
VARIABLE  buttonDel
VARIABLE  buttonNew

VARIABLE filechooserdialog_save
VARIABLE entryName
VARIABLE button_create
VARIABLE button_cancel

VARIABLE entry_degree
VARIABLE button_refr
\ различные итераторвы
  0 , HERE  64 ALLOT  VALUE iter_store_pribor
  0 , HERE  64 ALLOT  VALUE iter_store_text 


 : ->degree  
 || D: adr D: u ||
  ." degree " 
 \ freq, decimal -- freq2** 
 entry_degree   @ 1 gtk_entry_get_text_length     DUP 0 > 
	IF 
		entry_degree @ 1 gtk_entry_get_text     adr !   u ! \ adr u 
	\	adr @ u @ TYPE CR
		adr @ u @  STR>S S>FLOAT 
		IF
			10e  \ metod-info FREQ_DEGREE @  
			FSWAP F**  \ возвели в степень 
		ELSE 1e THEN
	ELSE DROP 1e	THEN
 ;
  
 : Refresh_param_kal_list 
 kalibrovka @ ^  num_datas @  0 >
IF
	liststore_param_kal  @ 1 gtk_list_store_clear	 DROP
	kalibrovka @ ^  num_datas @  
	0 
	DO
\		I kalibrovka @ ^   take_freq_in_number F.
		I iter_store_pribor  liststore_param_kal  @  3 gtk_list_store_insert DROP   			
		 -1 I 0 iter_store_pribor liststore_param_kal  @ 5 gtk_list_store_set DROP 
	\	kalibrovka @  ^ num_datas_in_string @ 
	\	0 
	\	DO	
		I 0  kalibrovka @ ^ take_data_in_number  \ FDUP F.   \ F>D frequency

 \ F->Mega 
->degree  F/
   \   перевели в мгц 
		-1   >FNUM   STR>S  >R R@ STR@ DROP  1  iter_store_pribor liststore_param_kal  @ 5 gtk_list_store_set DROP 	R> STRFREE	
		I 1  kalibrovka @ ^  take_data_in_number \ FDUP F.  \ F>D
		-1   >FNUM STR>S  >R R@ STR@ DROP 2 iter_store_pribor liststore_param_kal  @ 5 gtk_list_store_set DROP 	R> STRFREE	
		kalibrovka @ ^ num_datas_in_string @ 2 >
		IF
			I 2  kalibrovka @ ^ take_data_in_number  FDUP F.  \ F>D
			
			-1   >FNUM STR>S  >R R@ STR@ DROP 3 iter_store_pribor liststore_param_kal  @ 5 gtk_list_store_set DROP 	R> STRFREE		
		THEN
	\	LOOP

		\ -1 I 0 adr u STR>S DUP >R STR@ DROP 1  s DUP >R STR@ DROP 2   iter_store_pribor liststore_param_prib  @ 9 gtk_list_store_set DROP R> STRFREE  R> STRFREE  
	CR
	LOOP  
\ kalibrovka @ ^ datas @  DUP . F@ F. 
THEN
; 


 
:NONAME 
\  0 DisableButon !
	win_pribor @ 1 gtk_widget_destroy DROP  BYE
	0 ;  1 CELLS  CALLBACK: on_pribor_destroy   

:NONAME  
	win_pribor @ 1 gtk_widget_destroy DROP    
	0 ;  1 CELLS  CALLBACK: buttonClosePribor_click 
 

: LoadKalFile {   \ s s2  flag file  }

	"" -> s
	-1 -> flag
	." DEPTH =" .S   ."  filechooserbutton_pribor_open  "  
	\ грузим имя настроек
	filechooserbutton_kal  @ 1 gtk_file_chooser_get_filename    -> file 
	."  gtk_file_chooser_get_filename = " file .  ." DEPTH =" .S 	CR
	file	0=
	IF 
		0   -> flag  
	THEN
	." DEPTH  include =" .S  ." flag=" flag .  CR
	flag	
	IF   
		\ грузим файл калибровки
		s STRFREE
		file ASCIIZ> STR>S   -> s \  DEPTH . 
		s STR@   ." INCLUDE FILE: " TYPE   CR
		s STR@ KalFeleName SWAP 1 + CMOVE 
		\ CR .S CR
\		  kalibrovka @ s STR@   INCLUDE-PROBE   -> file  \  ERR-INCLUDE-PROBE
		  s kalibrovka @ :LoadFile  \  DROP
		\ CR .S CR
\		file 
		IF 
			."  kalibrovka:  "  kalibrovka @    SeeDatas  
		ELSE     
			"  error_in_file_kalibrovka "  DUP STR@ TYPE TO_ERROR_PROG_BUFER 
		THEN 
\		CR	
	\	INCLUDE-PROBE   
\	.S \ -> file
	THEN

	
;

:NONAME  \ { \ s s2  flag file }
|| D: file D: dir ||
	CR ." end- "   .S CR 
	LoadKalFile 
 	Refresh_param_kal_list
\	filechooserbutton_kal  @ 1 gtk_file_chooser_get_current_folder    dir !
\	filechooserbutton_kal  @ 1 gtk_file_chooser_get_filename    file !

\	."  gtk_file_chooser_get_filename = " file .  ." DEPTH =" .S 	CR
	\	" ./" >R  R@ STR@  DROP 
\	 dir @ filechooserbutton_kal  @ 2 gtk_file_chooser_set_current_folder DROP  \ R> STRFREE   ." filechooserbutton_pribor =" . CR	
\	 file	@ 	filechooserbutton_kal  @  gtk_file_chooser_get_filename    

	CR ." end "   .S CR 
\	kalibrovka @    ^ dispose
 	window @   ;  1 CELLS  
CALLBACK: filechooserbutton_kal_open  

 :NONAME
|| D: column D: path D: tree_view  D: model   ||
tree_view  ! path !  column !
	." TreeView_start_metod_click"  CR
	dialog @  1 gtk_widget_show DROP	
	\ выделенная строчка 
	tree_view  @ 1 gtk_tree_view_get_model    model ! 
	path @ iter_store_text model @ 3   gtk_tree_model_get_iter DROP \ (model, &iter, path_string 
	iter_store_text model @ 2 gtk_tree_model_get_string_from_iter    ASCIIZ> STR>S    \ STYPE ."  "
	S>FLOAT 
	IF
		F>D DROP num !   \ 1  
 		LoadKalFile
\		kalibrovka @ SeeDatas       \   F@ F.
		num @ 0  kalibrovka @   ^ take_data_in_number   \ F. \ F>D
\ F->Mega 
->degree  F/	
		>FNUM    STR>S
		DUP >R  STR@ DROP dialog_entry_freq @ 2 gtk_entry_set_text DROP R> STRFREE		
		num @ 1  kalibrovka @   ^ take_data_in_number   \ F>D
		>FNUM STR>S
		DUP >R  STR@ DROP dialog_entry_data   @ 2 gtk_entry_set_text DROP R> STRFREE
		num @ 2  kalibrovka @   ^ take_data_in_number   \ F>D
		>FNUM STR>S
		DUP >R  STR@ DROP dialog_entry_begindata @ 2 gtk_entry_set_text DROP R> STRFREE
 		kalibrovka @    ^ dispose
	THEN
	column  @ path @ tree_view @	window @   ;  3 CELLS  
CALLBACK:  treeview_param_prib_click 
	 
	 
 :NONAME   
."  buttonSavePribor "
\ dialog = gtk_file_chooser_dialog_new ("Open File",
\                                      parent_window,
\                                      action,
\                                      _("_Cancel"),
\                                      GTK_RESPONSE_CANCEL,
\                                      _("_Open"),
\                                      GTK_RESPONSE_ACCEPT,
\                                      NULL);

\	0
\	" gtk-save" STR@ DROP
\	GTK_RESPONSE_ACCEPT
\	0
\		" Save File" DUP >R STR@ DROP
\		3 gtk_file_chooser_dialog_new DROP  R> STRFREE


 	window @  ;  1 CELLS  
 CALLBACK: buttonSavePribor_click  
 
: LoadKalibrovka
	|| D: flag ||
	\ kalibrovka @ KalFeleName   ASCIIZ>  INCLUDE-PROBE     0 =  
	-1 flag !	
	 KalFeleName ASCIIZ>  STR>S kalibrovka @ ^ LoadFile  \ DROP  \ ASCIIZ>  INCLUDE-PROBE     0 =  flag !	
\	flag @
	IF 
		."  kalibrovka:  "  kalibrovka @    SeeDatas  
	ELSE     
		"  error_in_file_kalibrovka "  DUP STR@ TYPE TO_ERROR_PROG_BUFER 
	THEN 
\	-1 flag @
; 
 
:NONAME    \ { \ flag adr u   }
|| D: flag  D: adr  D: u  F: data ||
	-1  flag !
\	LoadKalibrovka flag !
LoadKalFile
	dialog_entry_freq  @ 1 gtk_entry_get_text_length   DUP 0 > 
	flag @ AND
	IF 
		dialog_entry_freq @ 1 gtk_entry_get_text     adr !   u ! \ adr u 	
		adr @ u @ ."  NUMBER 0 : "  TYPE ."  " 			
		adr @ u  @ STR>FLOAT      flag !  \ 1e6 F*  \ перевели в Гц !
\ Mega->F
->degree F*
		data  F! \ F. CR

		num @ 1 <  \ первое значение 
		IF ." o= " CR 
			1   kalibrovka @    ^  take_freq_in_number  
			data F@  F< 
			IF  \ если второе значение  меньше первого то  первое = второму
				0 0   kalibrovka @    ^  adr_data_in_number  F@ data    F! 
			THEN
		THEN
		  CR ." num @  . kalibrovka @ ^ num_datas   . "  num @  . kalibrovka @ ^ num_datas  @ . CR
		 	num @   kalibrovka @ ^ num_datas  @  1 - =  
		\ 0 
		IF ." max= " \ последнее значение 
			num @ 1 -   kalibrovka @    ^  take_freq_in_number  FDUP F.
			data F@  FDUP F. 
			F> 
			IF  \ если последнее значение  меньше предпоследнего то  первое = второму
				." max2= "
				  num @ 1-  0 kalibrovka @    ^  adr_data_in_number F@  data   F! 
			THEN
		THEN
		num @ 0 >  \ не первое значение 
		IF
			num @ 1 -   kalibrovka @    ^  take_freq_in_number  
			data F@ F> 
			IF  \ если введенное значение  меньше предыдущего то  введённое = предыдущему
				\ num @ 1 +   kalibrovka @    ^  take_freq_in_number   data F! 
				num @ 1 -  0 kalibrovka @    ^  adr_data_in_number F@  data   F! 			
			THEN
		THEN
		num @   kalibrovka @ ^ num_datas  @  1 - <  
		IF  \ не последнее значение 
			num @ 1 +   kalibrovka @    ^  take_freq_in_number  
			data F@ F< 
			IF  \ если введенное значение  больше следующего то  введённое = следующему
 				num @ 1 +  0 kalibrovka @    ^  adr_data_in_number F@  data   F! 						
			THEN
		THEN		
		data F@ num @ 0  kalibrovka @    ^  adr_data_in_number  F! \  . \ F>D		
	ELSE 
		DROP 0  flag ! 
	THEN
	dialog_entry_data @ 1 gtk_entry_get_text_length   DUP 0 > 
	flag @ AND
	IF 
		dialog_entry_data @ 1 gtk_entry_get_text     adr !   u ! \ adr u 	
		adr @ u @ ."  NUMBER 1 : "  TYPE ."  " 			
		adr @ u  @ STR>FLOAT     flag ! \ F. CR
		num @ 1  kalibrovka @    ^  adr_data_in_number  F! \  . \ F>D		
	ELSE 
		DROP 0  flag ! 
	THEN
 	
	dialog_entry_begindata  @ 1 gtk_entry_get_text_length   DUP 0 > 
	flag @ AND
	IF 
		dialog_entry_begindata  @ 1 gtk_entry_get_text     adr !   u ! \ adr u 	
		adr @ u @ ."  NUMBER 2 : "  TYPE ."  " 			
		adr @ u  @ STR>FLOAT     flag ! \ F. CR
		num @ 2  kalibrovka @    ^  adr_data_in_number  F! \  . \ F>D		
	ELSE 
		DROP 0  flag !
	THEN
	flag @ 
	IF 
		."  dialog -norma " CR 
		 \ " 1.txt"
		  KalFeleName ASCIIZ>  STR>S kalibrovka @ ^ SaveFile \ SaveData
	THEN	
\ .S	
	kalibrovka @    SeeDatas 
\	kalibrovka @    ^ dispose
	dialog @  1 gtk_widget_hide DROP 
	filechooserbutton_kal_open
	dialog   @ ;  1 CELLS  
CALLBACK: button_norma_click
 
:NONAME 	
	dialog @  1 gtk_widget_hide DROP  
	filechooserbutton_kal_open
	0 ;  1 CELLS  
CALLBACK: button_error_click

 
:NONAME 
	dialog @  1 gtk_widget_hide DROP  
	0 ;  1 CELLS  
CALLBACK: destroy_click
 
:NONAME 
	|| D: adr D: u ||
	filechooserdialog_save   @ 1 gtk_widget_destroy DROP     
	0 ;  1 CELLS  
CALLBACK:  filechooserdialog_save_destroy    


:NONAME 
	|| D: adr D: u D: file D: s ||
	." button_create_click" CR
	entryName  @ 1 gtk_entry_get_text_length   DUP 0 > 
	IF 
		entryName @ 1 gtk_entry_get_text     adr !   u ! \ adr u 
		adr @ u @ TYPE CR
		filechooserdialog_save  @ 1 gtk_file_chooser_get_current_folder file !
		 file @ ASCIIZ> STR>S   s ! \ STYPE
		" \" s @ S+
		adr @ u @ s @  STR+
		" .kal" s @ S+
		 s @ STYPE 
		s @ outFileCreate file !
		"  5 3 LoadDatas: " file @ StoFile
		file @ CRtoFile
		" LoadData:  1e0 0e  0e" file @ StoFile
		file @ CRtoFile
		" LoadData:  1e10 0e  0e" file @ StoFile
		file @ CRtoFile
		file @  outFileClose
	\	s kalibrovka @ ^ SaveData
		filechooserdialog_save   @ 1 gtk_widget_destroy DROP     
	ELSE 
		DROP
	THEN
\	filechooserbutton_kal_open
\	filechooserdialog_save_destroy	
	builder_pribor @   ;  1 CELLS  
CALLBACK:  button_create_click

:NONAME 
	filechooserdialog_save_destroy	
	builder_pribor @   ;  1 CELLS  
CALLBACK: button_cancel_click

:NONAME 
	." buttonNew_click" CR
 	 " filechooserdialog_save"  DUP >R STR@  DROP builder_pribor @ 2 gtk_builder_get_object  filechooserdialog_save !  R> STRFREE \ 2DROP
 	" destroy"  >R 0 0 0  [']  filechooserdialog_save_destroy  R@ STR@ DROP filechooserdialog_save   @ 6 g_signal_connect_data   R> STRFREE  DROP \ 2DROP 2DROP 2DROP
	 filefilter_kal @ filechooserdialog_save  @ 2 gtk_file_chooser_add_filter DROP
	 " ./metod/" >R  R@ STR@  DROP filechooserdialog_save  @ 2 gtk_file_chooser_set_current_folder   R> STRFREE   ." filechooserbutton_pribor =" . CR	
	 " entryName" >R  R@ STR@  DROP builder_pribor @ 2 gtk_builder_get_object entryName !    R> STRFREE \ 2DROP
	" button_create" >R  R@ STR@  DROP builder_pribor @ 2 gtk_builder_get_object button_create !    R> STRFREE \ 2DROP
   	" clicked"  >R 0 0 0  ['] button_create_click R@ STR@ DROP button_create @ 6 g_signal_connect_data   R> STRFREE  DROP \ 2DROP 2DROP 2DROP 
	 " button_cancel" >R  R@ STR@  DROP builder_pribor @ 2 gtk_builder_get_object button_cancel !    R> STRFREE \ 2DROP
  	" clicked"  >R 0 0 0  ['] button_cancel_click R@ STR@ DROP button_cancel @ 6 g_signal_connect_data   R> STRFREE  DROP \ 2DROP 2DROP 2DROP 
 	filechooserdialog_save  @  1 gtk_widget_show DROP \ DROP




	builder_pribor @  
	;  	1 CELLS  CALLBACK:  buttonNew_click 
 
:NONAME 
	|| D: flag ||  
-1  flag !
LoadKalFile
kalibrovka @    ^ num_datas @  kalibrovka @    ^ max_datas  1 - <
kalibrovka @    ^ num_datas @ 1 > OR
IF
	kalibrovka @    ^ num_datas @  1 - 0 kalibrovka @    ^  adr_data_in_number F@   
	kalibrovka @    ^ num_datas @      0 kalibrovka @    ^  adr_data_in_number F!   

	kalibrovka @    ^ num_datas @  1 - 1 kalibrovka @    ^  adr_data_in_number F@   
	kalibrovka @    ^ num_datas @      1 kalibrovka @    ^  adr_data_in_number F!   

	kalibrovka @    ^ num_datas @  1 - 2 kalibrovka @    ^  adr_data_in_number F@   
	kalibrovka @    ^ num_datas @      2 kalibrovka @    ^  adr_data_in_number F!  
	 
	kalibrovka @    ^ num_datas @ 1 +    kalibrovka @    ^ num_datas !

	KalFeleName ASCIIZ>  STR>S kalibrovka @ ^ SaveFile \ SaveData

	kalibrovka @    SeeDatas 	
\	kalibrovka @    ^ dispose	
	filechooserbutton_kal_open 
THEN
	window @  ;  1 CELLS  
CALLBACK: buttonAdd_click 

:NONAME  
	|| D: flag ||  
\	LoadKalibrovka
-1  flag !
LoadKalFile
	kalibrovka @    ^ num_datas @ 2 >
	IF
		kalibrovka @    ^ num_datas @ 1 -	kalibrovka @    ^ num_datas !
	THEN
	KalFeleName ASCIIZ>  STR>S kalibrovka @ ^ SaveFile \ SaveData
	kalibrovka @    SeeDatas 	
\	kalibrovka @    ^ dispose	
	filechooserbutton_kal_open
	window @  ;  1 CELLS  
CALLBACK: buttonDel_click 

 :NONAME 
 
\ 	."  press " CR
	filechooserbutton_kal  @   1 gtk_file_chooser_get_current_folder DUP 
	0<> 
	IF 
		DROP	\ ASCIIZ> TYPE 
	ELSE 
		DROP 	   " ./metod/" >R  R@ STR@  DROP filechooserbutton_kal  @ 2 gtk_file_chooser_set_current_folder   R> STRFREE   ." filechooserbutton_pribor =" . CR	
	THEN
 1 ;  1 CELLS 
 CALLBACK:  timer_ticket 


 :NONAME 
\ ."  entry_degree_activate "
\ Refresh_param_kal_list
	1 ;  1 CELLS 
 CALLBACK:  button_refr_click


: Startpribor
createtablkalibr
	pargv pargs  2  gtk_init  DROP \ 2DROP 
	0 gtk_builder_new   builder_pribor !
	error  " kalibr.glade"  >R R@ STR@  DROP  builder_pribor @ 3 gtk_builder_add_from_file DROP   R> STRFREE \ 2DROP	
	" pribor"  >R R@ STR@  DROP builder_pribor @ 2 gtk_builder_get_object win_pribor !  R> STRFREE \ 2DROP
	win_pribor @  1 gtk_widget_show DROP \ DROP

	\ ДЕЙСТВО ЗАКРЫТИЕ ПРОГРАММЫ
	" destroy"  >R 0 0 0  ['] on_pribor_destroy  R@ STR@ DROP win_pribor @ 6 g_signal_connect_data   R> STRFREE  DROP \ 2DROP 2DROP 2DROP
	" buttonClosePribor" >R  R@ STR@  DROP builder_pribor   @ 2 gtk_builder_get_object buttonClosePribor  !    R> STRFREE \ 2DROP	
	" clicked"  >R 0 0 0  ['] buttonClosePribor_click R@ STR@ DROP buttonClosePribor @ 6 g_signal_connect_data   R> STRFREE  DROP \ 2DROP 2DROP 2DROP 

	 " buttonSavePribor" >R  R@ STR@  DROP builder_pribor   @ 2 gtk_builder_get_object buttonSavePribor !    R> STRFREE \ 2DROP
	  " clicked"  >R 0 0 0  ['] buttonSavePribor_click R@ STR@ DROP buttonSavePribor @ 6 g_signal_connect_data   R> STRFREE  DROP \ 2DROP 2DROP 2DROP
    
	  \ указатель для загрузки и  сохранении , устанавливаем фильтр для приборов
	 " filechooserbutton_kal" >R  R@ STR@  DROP builder_pribor   @  2 gtk_builder_get_object filechooserbutton_kal !    R> STRFREE \ 2DROP
	 " filefilter_kal" >R  R@ STR@  DROP builder_pribor   @  2 gtk_builder_get_object filefilter_kal !    R> STRFREE \ 2DROP
	 filefilter_kal @ filechooserbutton_kal  @ 2 gtk_file_chooser_add_filter DROP
	   " ./metod/" >R  R@ STR@  DROP filechooserbutton_kal  @ 2 gtk_file_chooser_set_current_folder   R> STRFREE   ." filechooserbutton_pribor =" . CR	
	 " file-set"    >R 0 0 0  ['] filechooserbutton_kal_open  R@ STR@ DROP filechooserbutton_kal  @ 6 g_signal_connect_data   R> STRFREE  DROP \ 2DROP 2DROP 2DROP
 \	 " file-activated"    >R 0 0 0  ['] filechooserbutton_kal_press  R@ STR@ DROP filechooserbutton_kal  @ 6 g_signal_connect_data   R> STRFREE  DROP \ 2DROP 2DROP 2DROP
 

	  \ готовим окошко под параметры оборудования
	    " treeview_param_prib"  >R R@ STR@ DROP builder_pribor    @ 2 gtk_builder_get_object treeview_param_kal ! R> STRFREE
	    " liststore_param_kal" >R R@ STR@ DROP builder_pribor   @ 2 gtk_builder_get_object liststore_param_kal ! R> STRFREE  
	    " row-activated"    >R 0 0 0  ['] treeview_param_prib_click R@ STR@ DROP treeview_param_kal @ 6 g_signal_connect_data   R> STRFREE  DROP \ 2DROP 2DROP 2DROP

	 " buttonAdd" >R  R@ STR@  DROP builder_pribor   @ 2 gtk_builder_get_object buttonAdd  !    R> STRFREE \ 2DROP
	  " clicked"  >R 0 0 0  ['] buttonAdd_click R@ STR@ DROP buttonAdd @ 6 g_signal_connect_data   R> STRFREE  DROP \ 2DROP 2DROP 2DROP 

	 " buttonDel" >R  R@ STR@  DROP builder_pribor   @ 2 gtk_builder_get_object buttonDel  !    R> STRFREE \ 2DROP
	  " clicked"  >R 0 0 0  ['] buttonDel_click R@ STR@ DROP buttonDel @ 6 g_signal_connect_data   R> STRFREE  DROP \ 2DROP 2DROP 2DROP 

	 " buttonNew" >R  R@ STR@  DROP builder_pribor   @ 2 gtk_builder_get_object buttonNew !    R> STRFREE \ 2DROP
	  " clicked"  >R 0 0 0  ['] buttonNew_click R@ STR@ DROP buttonNew @ 6 g_signal_connect_data   R> STRFREE  DROP \ 2DROP 2DROP 2DROP 


	 " entry_degree" >R  R@ STR@  DROP builder_pribor @ 2 gtk_builder_get_object entry_degree !    R> STRFREE \ 2DROP
	\  " move-cursor"  >R 0 0 0  ['] entry_degree_activate R@ STR@ DROP entry_degree @ 6 g_signal_connect_data   R> STRFREE  DROP \ 2DROP 2DROP 2DROP 
	 " button_refr" >R  R@ STR@  DROP builder_pribor   @ 2 gtk_builder_get_object button_refr !    R> STRFREE \ 2DROP
	  " clicked"  >R 0 0 0  ['] button_refr_click R@ STR@ DROP button_refr @ 6 g_signal_connect_data   R> STRFREE  DROP \ 2DROP 2DROP 2DROP 




	\ 1 ['] timer_pribor  1000 3 g_timeout_add DROP


	\ поднятие диалога выбора  вот тут проблемма что если удалять и включать. то  втором и последующих включениях появляетя голое окно без кнопочек.
	\ " dialog_label" >R  R@ STR@  DROP builder_pribor @ 2 gtk_builder_get_object dialog_label !    R> STRFREE \ изменяемая надпись
	 " dialog"  DUP >R STR@  DROP builder_pribor @ 2 gtk_builder_get_object  dialog !  R> STRFREE \ 2DROP
\ убираем штатное закрытие, и меняем его на  метод кнопки
	 " desroy-event"  >R 0 0 0  ['] destroy_click   R@ STR@ DROP dialog @ 6 g_signal_connect_data   R> STRFREE  DROP \ 2DROP 2DROP 2DROP


	 " button_norma" >R  R@ STR@  DROP builder_pribor @  2 gtk_builder_get_object button_norma !    R> STRFREE \ 2DROP
	 " clicked"  >R 0 0 0  ['] button_norma_click   R@ STR@ DROP button_norma @ 6 g_signal_connect_data   R> STRFREE  DROP \ 2DROP 2DROP 2DROP
	 " button_error" >R  R@ STR@  DROP builder_pribor @  2 gtk_builder_get_object button_error !    R> STRFREE \ 2DROP
	 " clicked"  >R 0 0 0  ['] button_error_click   R@ STR@ DROP button_error @ 6 g_signal_connect_data   R> STRFREE  DROP \ 2DROP 2DROP 2DROP
	 " dialog_entry_freq" >R  R@ STR@  DROP builder_pribor @ 2 gtk_builder_get_object dialog_entry_freq !    R> STRFREE \ 2DROP
	 " dialog_entry_data" >R  R@ STR@  DROP builder_pribor @ 2 gtk_builder_get_object dialog_entry_data !    R> STRFREE \ 2DROP
	 " dialog_entry_begindata" >R  R@ STR@  DROP builder_pribor @ 2 gtk_builder_get_object dialog_entry_begindata !    R> STRFREE \ 2DROP	


	\ " dialog_filechooserbutton"  >R  R@ STR@  DROP builder_pribor @  2 gtk_builder_get_object dialog_filechooserbutton !    R> STRFREE \ 2DROP
	\   dialog @  1 gtk_widget_hide DROP 
	 \ dialog  @  1 gtk_widget_show DROP \ DROP

	0 ['] timer_ticket  1000 3 g_timeout_add DROP


	\ устанавливаем фильтр для настроек
	\ filefilter_nast @ filechooserbutton_file_nastr   @ 2 gtk_file_chooser_add_filter DROP
	 0 gtk_main  DROP 
;


0 VALUE runthread

: start
STARTLOG
	 ['] Startpribor TASK TO runthread
	  runthread START  
; 

 
 
 
 
\ : T S" .\metod\*.*" ['] addListMetod FIND-FILES ; T
\ )
   start


    FALSE TO ?GUI
  \   ' CECONSOLE MAINX !
	 ' start MAINX !
        S" kalfile.exe"  SAVE
\	BYE

