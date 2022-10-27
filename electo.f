STARTLOG
 REQUIRE CAPI: lib/win/api-call/capi.f
 REQUIRE gtk_init  gtk-api.spf
 REQUIRE CASE  lib/ext/case.f
 REQUIRE WildCMP-U ~pinka/lib/mask.f \ \ сравнение строки и маски, для  проверки ответа оборудования
 REQUIRE objLocalsSupport ~day/hype3/locals.f \ локальные переменные
 REQUIRE tabl_kalibr  ~disa/kalibr_hype.f      \ объекты
 REQUIRE dBuV->V  ~disa/algoritm.f             \ различные алгоритмы
 REQUIRE FIND-FILES ~ac\FINDFILE.F         \ поиск файлов
 REQUIRE AddNode ~ac\STR_LIST.F            \ список
 REQUIRE STR@ ~ac\str5.f                    \ работа с динамическими строками
 REQUIRE F. ~disa\dopoln.f
 REQUIRE socket_port ~disa/socket.f
 REQUIRE com_port ~disa/COMM.F

  
: LOAD_TO_BUFER { s-adr adr \ u   -- }
s-adr STR@  ." LOAD_TO_BUFER "  DUP . ." : " TYPE CR
s-adr STR@  DUP 255 > IF DROP 255 THEN -> u
adr  1+ u CMOVE 
s-adr STRFREE
u adr  C!

;

\ работа с приборами (временно, не придумал куда девать)
\ VECT Save_PriborPassport  \ процедура сохранения данных прибора 
\ VECT  PriborPassportSeeOne \ \ \ подготовить в выводу описание переменной из настроек
\ VECT PriborinterfaceSeeOne \ описание интерфейсов
\ VECT SaveInterface	   \ процедура сохранения информации об интерфейсах
\ VECT FileInterface         \ команда показа файла интерфейса  
REQUIRE PriborPassport priborpassport.f

\ оболочка для пользователя
VARIABLE pargv
VARIABLE pargs
VARIABLE window
VARIABLE builder

VARIABLE DisableButon


HERE  0 , 256 ALLOT VALUE FulDirectory  \ путь к программе
HERE  0 , 64 ALLOT VALUE Directory  \ путь к методам программы
VARIABLE ListMetod \ список имеющихся методов




: addListMetod
\ TYPE CR 
"" DUP >R STR+  R> \ DUP  STR@ TYPE CR 
 ListMetod  AddNode

;


\ графика
VARIABLE  button_load_metod
VARIABLE button_last_metod
VARIABLE button_exit
VARIABLE TreeView_metod
VARIABLE liststore_metod
VARIABLE image_metod

 0 , HERE  64 ALLOT  VALUE iter_store_metod


VARIABLE error  \ сюда скидывать номер ошибки 
: act_on_window_destroy    CR ." Exit " 0 gtk_main_quit DROP     BYE ;


:NONAME  act_on_window_destroy  
	0 ;  1 CELLS  CALLBACK: on_window_destroy 

:NONAME  act_on_window_destroy  
	0 ;  1 CELLS  CALLBACK: button_exit_click

:NONAME  ." button_last_metod_click" CR
	0 ;  1 CELLS  CALLBACK: button_last_metod_click

: EnableWiget   { flag }
 flag button_load_metod @ 2 gtk_widget_set_sensitive DROP
 flag button_last_metod @ 2 gtk_widget_set_sensitive DROP
 flag TreeView_metod @ 2 gtk_widget_set_sensitive DROP

;

:NONAME    {   \ tekFile }
  ." button_load_metod_click" CR
  -1 DisableButon !
\  0 button_load_metod @ 2 gtk_widget_set_sensitive DROP
\  0 button_last_metod @ 2 gtk_widget_set_sensitive DROP
\ 0 button_last_metod @ 2 gtk_widget_set_sensitive DROP
0 EnableWiget    
  Directory   ASCIIZ>  "" DUP -> tekFile  STR+
    " /metod.spf" tekFile  S+
  ." load metod file :" tekFile     STR@ TYPE ."  " CR

  tekFile  STR@  INCLUDED
  tekFile  STRFREE
	0 ;  1 CELLS  CALLBACK: button_load_metod_click

\ :NONAME   {  column path tree_view \ model  flag tekFile }
:NONAME   {  tree_view \ model  flag tekFile path column }
\ CR column . path . tree_view . CR
 ^ column  ^ path tree_view  3  gtk_tree_view_get_cursor     DROP 

\ выделенная строчка 
  tree_view  1 gtk_tree_view_get_model   -> model 
  path iter_store_metod  model 3   gtk_tree_model_get_iter DROP \ (model, &iter, path_string)
 -1 ^ tekFile 0	iter_store_metod model 5 gtk_tree_model_get DROP
\ './metod/'+tekFile+'/bildo.png'
 tekFile ASCIIZ>  " ./metod/" DUP
  -> tekFile  STR+  
  tekFile     STR@  Directory  SWAP  2DUP +   0 SWAP C! CMOVE \ сохранили выбранный метод для дальнейшего использования   закрыли строчку "0"

 " /bildo.png" tekFile  S+
  ." load grafic file :" tekFile     STR@ TYPE ."  " CR
tekFile STR@ DROP image_metod @ 2 gtk_image_set_from_file DROP 

tree_view 0 ; 1 CELLS CALLBACK:  TreeView_metod_click
\ column path tree_view 0 ; 3 CELLS CALLBACK:  TreeView_metod_click


:NONAME  \ ." ."
DisableButon @ 0=
IF -1 EnableWiget  
\ -1 button_load_metod @ 2 gtk_widget_set_sensitive DROP
\ -1 button_last_metod @ 2 gtk_widget_set_sensitive DROP
THEN
	window @  ;  1 CELLS CALLBACK:  timer_ticket 
	
: work_windows { \ I f fdata node  lfname fname[ 125 ] -- }

\  krei la unua fenestro
 pargv pargs  2  gtk_init  DROP \ 2DROP 
  0 gtk_builder_new   builder !
  error  " electo.glade"  >R R@ STR@  DROP  builder @ 3 gtk_builder_add_from_file DROP   R> STRFREE \ 2DROP 
   \ Вот тут теоретически может отработать автоподсоединение.. но как взаимодействуют данные из формы с переменными- мне неизвестно 
   \ builder.connect_signals(WinElectro())
   \ поэтому надежней подсоединить все вручную
  " windowelecto"  >R R@ STR@  DROP builder @ 2 gtk_builder_get_object window !  R> STRFREE \ 2DROP
   window @  1 gtk_widget_show DROP \ DROP
 
    \ ДЕЙСТВО ЗАКРЫТИЕ ПРОГРАММЫ
   " destroy"  >R 0 0 0  ['] on_window_destroy  R@ STR@ DROP window @ 6 g_signal_connect_data   R> STRFREE  DROP \ 2DROP 2DROP 2DROP

   " button_load_metod" >R  R@ STR@  DROP builder @ 2 gtk_builder_get_object button_load_metod !    R> STRFREE \ 2DROP
   " clicked"  >R 0 0 0  ['] button_load_metod_click   R@ STR@ DROP button_load_metod @ 6 g_signal_connect_data   R> STRFREE  DROP \ 2DROP 2DROP 2DROP

 " button_last_metod" >R  R@ STR@  DROP builder @ 2 gtk_builder_get_object button_last_metod !    R> STRFREE \ 2DROP
  " clicked"  >R 0 0 0  ['] button_last_metod_click   R@ STR@ DROP button_last_metod  @ 6 g_signal_connect_data   R> STRFREE  DROP \ 2DROP 2DROP 2DROP

 " button_exit" >R  R@ STR@  DROP builder @ 2 gtk_builder_get_object button_exit  !    R> STRFREE \ 2DROP
  " clicked"  >R 0 0 0  ['] button_exit_click R@ STR@ DROP button_exit   @ 6 g_signal_connect_data   R> STRFREE  DROP \ 2DROP 2DROP 2DROP

   \  en la fenestro elektita listo kiu estas konektita al la programo
   \ TreeView_metod= builder.get_object('TreeView_metod')
   \ liststore_metod= builder.get_object('liststore_metod')
   \ liststore_metod.clear()
    " TreeView_metod"  >R R@ STR@ DROP builder @ 2 gtk_builder_get_object TreeView_metod  ! R> STRFREE
    " liststore_metod" >R R@ STR@ DROP builder @ 2 gtk_builder_get_object liststore_metod ! R> STRFREE  
   iter_store_metod liststore_metod  @ 2 gtk_list_store_append DROP
   \  la komencanta bildo
   \ image_metod = builder.get_object('image_metod') 
   \ image_metod.set_from_file("./starto.png")
    " image_metod"   >R R@ STR@ DROP builder     @ 2 gtk_builder_get_object image_metod ! R> STRFREE
    " ./starto.png"  >R R@ STR@ DROP image_metod @ 2 gtk_image_set_from_file R> STRFREE
 
 
   \ # listo
   \ directory = './metod'
   \ files = os.listdir(directory)
   \ tekFile=""
   \ print  files 
   \ for i in range(len(files)):
	\ f = open('./metod/'+files[i]+'/info.txt', 'r')
	\ iter=liststore_metod.append("")
	\ liststore_metod.set(iter,2,i)
	\ liststore_metod.set(iter,1,files[i] )
	\ liststore_metod.set(iter,0,f.read() )
 \ ---------------------------------------------------------------------
 \ работа со списком методов --- загружаем список в листбокс----------------------------------------
 \ ---------------------------------------------------------------------
      liststore_metod  @ 1 gtk_list_store_clear
  \ читаем список методов ( каталогов),\ создаем список и выводим его на экран
     S" .\metod\*.*" ['] addListMetod FIND-FILES
     ListMetod FirstNode  -> node  
     0 -> I
     BEGIN
      node NodeValue  DUP  STR@  -> lfname fname[ lfname CMOVE \ сохраняем имя для дальнейшегоиспользования
       " ./metod/" DUP >R S+  R> \  ./metod/'name'
       >R " /info.txt" R@ S+ R>   \ ./metod/'name'/info.txt
       \ STYPE   
       \ прочитать из файла описание метода
       STR@  R/O OPEN-FILE  
       0= IF -> f
          1024 1 + ALLOCATE THROW -> fdata 
          fdata CELL + 1020  f READ-FILE THROW fdata  !
          fdata CELL + fdata @  TYPE CR
          I iter_store_metod  liststore_metod @  3 gtk_list_store_insert DROP
       
       \        CR fname[ lfname "" DUP >R STR+ R> STYPE CR
       
          -1 fname[ lfname "" DUP >R STR+ R> 
	  
          DUP >R STR@ DROP 0  fdata CELL + fdata @ "" DUP >R STR+ R> 
	  DUP >R STR@ DROP 1  I 2 iter_store_metod  liststore_metod    @ 9 gtk_list_store_set DROP R> STRFREE  R> STRFREE  

          I 1+ -> I
          fdata FREE DROP  \ освободили память из под данных файла
	  f CLOSE-FILE
      THEN
    \ 1 \ fname[ lfname "" STR+ 
    \ " 2" DUP >R STR@ DROP 0 \  fdata 1 + fdata C@  
    \  " 1" STR+ DUP >R STR@ DROP 1  123 2 iter_store_metod  liststore_metod    @ 9 gtk_list_store_set DROP R> STRFREE  R> STRFREE  

    node NextNode -> node
    node 0=
    UNTIL
 ListMetod FreeList \ освободили память из под  списка
 \ ---------------------------------------------------------------------
 \ --------------закончена работа со списком методов -------------------
 \ ---------------------------------------------------------------------

\  " row-activated"   
  " cursor-changed"
  >R 0 0 0  ['] TreeView_metod_click   R@ STR@ DROP TreeView_metod @ 6 g_signal_connect_data   R> STRFREE  DROP \ 2DROP 2DROP 2DROP
 0 ['] timer_ticket  1500 3 g_timeout_add DROP
  0 gtk_main  DROP 
   ;
   
   

0 VALUE runthread

: start
STARTLOG 
 ['] work_windows TASK TO runthread
  runthread START
; 
 
\ : T S" .\metod\*.*" ['] addListMetod FIND-FILES ; T

 start
\ EOF
  FALSE TO ?GUI
  \   ' CECONSOLE MAINX !
	 ' start MAINX !
         S" kulemc.exe"  SAVE
\	BYE
\ start
