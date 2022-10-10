\ управление файлами калибровки  
STARTLOG
 REQUIRE CAPI: lib/win/api-call/capi.f
 REQUIRE gtk_init  \emctest/gtk-api.spf
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
0 , HERE  512 ALLOT  VALUE KalFeleName \ имя калибровки
 
 
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

 
 
\ :NONAME 
\	win_pribor @ 1 gtk_widget_destroy DROP  BYE
\	0 ;  1 CELLS  CALLBACK: on_pribor_destroy   

\ :NONAME  
\	win_pribor @ 1 gtk_widget_destroy DROP    
\	0 ;  1 CELLS  CALLBACK: buttonClosePribor_click  
  
  
  

: Startpribor
createtablkalibr
	pargv pargs  2  gtk_init  DROP \ 2DROP 
	0 gtk_builder_new   builder_pribor !
	error  " kalibr.glade"  >R R@ STR@  DROP  builder_pribor @ 3 gtk_builder_add_from_file DROP   R> STRFREE \ 2DROP	
	" pribor"  >R R@ STR@  DROP builder_pribor @ 2 gtk_builder_get_object win_pribor !  R> STRFREE \ 2DROP
	win_pribor @  1 gtk_widget_show DROP \ DROP
	\ ДЕЙСТВО ЗАКРЫТИЕ ПРОГРАММЫ
\	" destroy"  >R 0 0 0  ['] on_pribor_destroy  R@ STR@ DROP win_pribor @ 6 g_signal_connect_data   R> STRFREE  DROP \ 2DROP 2DROP 2DROP
 \	" buttonClosePribor" >R  R@ STR@  DROP builder_pribor   @ 2 gtk_builder_get_object buttonClosePribor  !    R> STRFREE \ 2DROP	
\	" clicked"  >R 0 0 0  ['] buttonClosePribor_click R@ STR@ DROP buttonClosePribor @ 6 g_signal_connect_data   R> STRFREE  DROP \ 2DROP 2DROP 2DROP 
\	 " buttonSavePribor" >R  R@ STR@  DROP builder_pribor   @ 2 gtk_builder_get_object buttonSavePribor !    R> STRFREE \ 2DROP
\	  " clicked"  >R 0 0 0  ['] buttonSavePribor_click R@ STR@ DROP buttonSavePribor @ 6 g_signal_connect_data   R> STRFREE  DROP \ 2DROP 2DROP 2DROP
    
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
\	  " clicked"  >R 0 0 0  ['] buttonAdd_click R@ STR@ DROP buttonAdd @ 6 g_signal_connect_data   R> STRFREE  DROP \ 2DROP 2DROP 2DROP 

	 " buttonDel" >R  R@ STR@  DROP builder_pribor   @ 2 gtk_builder_get_object buttonDel  !    R> STRFREE \ 2DROP
\	  " clicked"  >R 0 0 0  ['] buttonDel_click R@ STR@ DROP buttonDel @ 6 g_signal_connect_data   R> STRFREE  DROP \ 2DROP 2DROP 2DROP 

	 " buttonNew" >R  R@ STR@  DROP builder_pribor   @ 2 gtk_builder_get_object buttonNew !    R> STRFREE \ 2DROP
\	  " clicked"  >R 0 0 0  ['] buttonNew_click R@ STR@ DROP buttonNew @ 6 g_signal_connect_data   R> STRFREE  DROP \ 2DROP 2DROP 2DROP 


	 " entry_degree" >R  R@ STR@  DROP builder_pribor @ 2 gtk_builder_get_object entry_degree !    R> STRFREE \ 2DROP
	\  " move-cursor"  >R 0 0 0  ['] entry_degree_activate R@ STR@ DROP entry_degree @ 6 g_signal_connect_data   R> STRFREE  DROP \ 2DROP 2DROP 2DROP 
	 " button_refr" >R  R@ STR@  DROP builder_pribor   @ 2 gtk_builder_get_object button_refr !    R> STRFREE \ 2DROP
\	  " clicked"  >R 0 0 0  ['] button_refr_click R@ STR@ DROP button_refr @ 6 g_signal_connect_data   R> STRFREE  DROP \ 2DROP 2DROP 2DROP 




	\ 1 ['] timer_pribor  1000 3 g_timeout_add DROP


	\ поднятие диалога выбора  вот тут проблемма что если удалять и включать. то  втором и последующих включениях появляетя голое окно без кнопочек.
	\ " dialog_label" >R  R@ STR@  DROP builder_pribor @ 2 gtk_builder_get_object dialog_label !    R> STRFREE \ изменяемая надпись
	 " dialog"  DUP >R STR@  DROP builder_pribor @ 2 gtk_builder_get_object  dialog !  R> STRFREE \ 2DROP
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

 уайцпкйукпйу
   start