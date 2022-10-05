REQUIRE  HYPE ~day\hype3\hype3.f

CLASS virtual_port
CELL PROPERTY idport


: init ;

: open   ."  open= " STYPE . CR ;
  
: close ;
: write \ { str  --  }   
STYPE ."  "
;

: read \ { obj \ str --  adr u  }
" 1"  DUP STR@ TYPE ."  "

;

;CLASS
