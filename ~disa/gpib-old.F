\  работа с  сокетами, на основе рсокет  ~ac
\  все лежит в отдельном словаре
 REQUIRE  F. ~disa\dopoln.f

\ REQUIRE UseDLL ~nn/lib/usedll.f
\  UseDLL Gpib-32.dll
\ WINAPI: ibdev Gpib-32.dll
\ WINAPI: ibonl Gpib-32.dll
\ WINAPI: ibwrt Gpib-32.dll
\ WINAPI: ibrd Gpib-32.dll
\ WINAPI: ibclr Gpib-32.dll

WINAPI: SendDataBytes Gpib-32.dll
WINAPI: EnableRemote Gpib-32.dll



\ REQUIRE  { lib\ext\locals.f
\ REQUIRE STR@         ~ac/lib/str5.f
REQUIRE  HYPE ~disa\~day\hype3\hype3.f

CLASS old_gpib_port
32 CELLS CONSTANT num_bufer_port
CELL PROPERTY BoardIndex
CELL PROPERTY idport
 num_bufer_port DEFS bufer_port

\ : init SocketsStartup THROW ;

: open  ( adr gbib \ -- )
0x02 0 EnableRemote
\ BoardIndex ! >R 
\ 0 1 13 0 R>  BoardIndex @ ibdev  idport !  
\ idport @ ibclr DROP
;

\ : close \ idport @ fclose  
\ idport @ ibonl  
\ BoardIndex @  ibonl 
\ ;
: write   { str  --  }   
  " {CRLF}" str S+  str
 STR@ SWAP idport @ >R >R >R 1 R> R> R> SendDataBytes DROP
\ fputs   
str  STRFREE
;

\ : read \ { obj \ str --  c-adr-u  }
 \ num_bufer_port 0 DO bufer_port   I + 0! LOOP
 \ num_bufer_port bufer_port   idport @ ibrd  DROP 
  \   bufer_port   ASCIIZ>   "" DUP >R STR+ R>
   
   \ >R STR@ -> str obj 8 + str  CMOVE  
 \ str  obj  4 + !  obj 8 + str   
 \ R> STRFREE
\ STYPE
\ num_bufer_port  0 DO bufer_port   I + C@ . LOOP
;


;CLASS

(
  gpib_port NEW nrvd
  4 0 nrvd open
\  " INP:SEL {''} B {''} " nrvd write \ переключение каналов
\ " *IDN?" nrvd write
 " *TRG" nrvd write
\  " 192.168.0.19" 5025 smb100    open
\   "  *IDN?" smb100 write
\ " FREQ                20000000"        smb100 write
100 PAUSE
   nrvd read  STYPE
 nrvd close
 nrvd dispose
)