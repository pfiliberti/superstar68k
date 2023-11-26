' DEFINT A-Z

 OPEN "j:data.dat" FOR OUTPUT AS #2
 
 OPEN "g:reel1.dat" FOR INPUT AS #3

	FOR y1 = 1 TO 50

	FOR x = 1 TO 5
		INPUT #3, y
		INPUT #3, c
       
		PRINT #2, y; ","; c;
		PRINT y; ","; c;
	NEXT x
		PRINT #2, " "
		PRINT
	NEXT y1



 CLOSE #3
 CLOSE #2

