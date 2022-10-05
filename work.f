: TYPE_BUFER { bufer } 
bufer  1+ 
bufer  C@   DUP 0 > IF TYPE ELSE 2DROP ."  no info in buffer "  THEN 
;