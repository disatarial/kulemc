\ создание и редакторование калибровочных файлов
 REQUIRE CAPI: lib/win/api-call/capi.f
 REQUIRE gtk_init  gtk-api.f
 REQUIRE  CASE  lib/ext/case.f
 REQUIRE WildCMP-U ~pinka/lib/mask.f \ \ сравнение строки и маски, для  проверки ответа оборудования
 REQUIRE  objLocalsSupport ~day/hype3/locals.f \ локальные переменные
 REQUIRE  tabl_kalibr  ~disa/kalibr_hype.f      \ объекты
 REQUIRE  dBuV->V  ~disa/algoritm.f             \ различные алгоритмы
 REQUIRE FIND-FILES ~ac\FINDFILE.F         \ поиск файлов
 REQUIRE AddNode ~ac\STR_LIST.F            \ список
 REQUIRE  STR@ ~ac\str5.f                    \ работа с динамическими строками


VARIABLE error  \ сюда скидывать номер ошибки 

0
CELL -- domain
CELL -- code \ 
CELL -- message
CONSTANT GError
HERE DUP >R GError  DUP ALLOT ERASE VALUE GtkError

\ оболочка для пользователя
VARIABLE pargv
VARIABLE pargs
VARIABLE window
VARIABLE builder
\ кнопки
VARIABLE  button_exit_kal
VARIABLE  button_save_kal

: act_on_window_destroy  BYE
;
:NONAME  act_on_window_destroy  
	0 ;  1 CELLS  CALLBACK: on_window_destroy_kal
:NONAME  act_on_window_destroy  
	0 ;  1 CELLS  CALLBACK: button_exit_kal_click
	
:NONAME  ." button_save_kal_click" CR 

	0 ;  1 CELLS  CALLBACK: button_save_kal_click



: work_kal { \ I f fdata node  lfname fname[ 32 ] -- }

\  krei la unua fenestro
 pargv pargs  2  gtk_init  DROP \ 2DROP 
  0 gtk_builder_new   builder !
  error  " kal.glade"  >R R@ STR@  DROP  builder @ 3 gtk_builder_add_from_file DROP   R> STRFREE \ 2DROP 
   \ Вот тут теоретически может отработать автоподсоединение.. но как взаимодействуют данные из формы с переменными- мне неизвестно 
   \ builder.connect_signals(WinElectro())
   \ поэтому надежней подсоединить все вручную
  " window_kal"  >R R@ STR@  DROP builder @ 2 gtk_builder_get_object window !  R> STRFREE \ 2DROP

   \ ДЕЙСТВО ЗАКРЫТИЕ ПРОГРАММЫ
   " destroy"  >R 0 0 0  ['] on_window_destroy_kal  R@ STR@ DROP window @ 6 g_signal_connect_data   R> STRFREE  DROP \ 2DROP 2DROP 2DROP

   " button_save_kal" >R  R@ STR@  DROP builder @ 2 gtk_builder_get_object button_save_kal !    R> STRFREE \ 2DROP
   " clicked"  >R 0 0 0  ['] button_save_kal_click   R@ STR@ DROP button_save_kal @ 6 g_signal_connect_data   R> STRFREE  DROP \ 2DROP 2DROP 2DROP


 " button_exit_kal" >R  R@ STR@  DROP builder @ 2 gtk_builder_get_object button_exit_kal  !    R> STRFREE \ 2DROP
  " clicked"  >R 0 0 0  ['] button_exit_kal_click R@ STR@ DROP button_exit_kal   @ 6 g_signal_connect_data   R> STRFREE  DROP \ 2DROP 2DROP 2DROP


   window @  1 gtk_widget_show DROP \ DROP
  0 gtk_main  DROP 
  ;
  
0 VALUE runthread

: start
 ['] work_kal TASK TO runthread
  runthread START
; 
 
\ : T S" .\metod\*.*" ['] addListMetod FIND-FILES ; T

 start
