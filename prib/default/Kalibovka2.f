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
  