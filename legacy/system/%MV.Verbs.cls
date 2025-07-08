/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include LANG11

Class %MV.Verbs Extends %RegisteredObject [ Abstract, Language = objectscript, ServerOnly = 1, System = 4 ]
{

ClassMethod ListDict() [ Language = mvbasic ]
{
	
	DIM %MVCommandLine ()
	MULTI=COUNT(SYSTEM(15),"M")
	SIMPLE=COUNT(SYSTEM(15),"S")
    H1="Dictionary of ":@FILENAME:" 'CLTCLL'"
    H2="AMC NAME/TITLE           CONVERSION/CORRELATIVE                            MAX'L'"
    H3="------------------------------------------------------------------------------"
    HEADING H1:H2:H3
    LOOP WHILE "%SYSTEM.MV"->TCL2Next() = 1 DO
		IF @ID[1,1]='@' THEN CONTINUE
        ATYPE=@RECORD<1>[1,1]
        IF ATYPE='D' OR ATYPE='I' THEN
          IF MULTI AND @RECORD<6>#'M' THEN CONTINUE
          IF @RECORD<10>#'' THEN CONTINUE
          ACONV=@RECORD<3>; ACORR=@RECORD<2>
          LJ=@RECORD<5>
          NAME=@RECORD<4>
          IF ATYPE='I' THEN @RECORD<2>=0
        END ELSE
          ACONV=@RECORD<7>; ACORR=@RECORD<8>
          Ln=@RECORD<10>; JUST=@RECORD<9>
          LJ=Ln:JUST
          NAME=@RECORD<3>
        END
        IF SIMPLE THEN
          PRINT @RECORD<2>'L#4':NAME[1,20]'L#21'
        END ELSE
          L1=@RECORD<2>'L#4':@ID[1,20]'L#21':ACONV[1,50]'L#51':LJ
          L2='''L#4':NAME[1,20]'L#21':ACORR[1,50]'L#51'
          PRINT L1
          PRINT L2
          PRINT
        END
    REPEAT
}

ClassMethod ListIndex() [ Language = mvbasic ]
{
	DIM %SourceFileObj()
	DIM %MVCommandLine ()
	IF COUNT(SYSTEM(15),"D") THEN
		idxName = $Get(%MVCommandLine(3))
		lastkey = ""
		keyCount = 0
		If idxName="" THEN STOPM "IndexName"
		OPENINDEX @FILENAME,idxName TO idx ELSE STOPM "Index Does Not Exist"
		H1="Keys in index ":@FILENAME:" ":idxName:"'CLL'"
	    H2="Key"'L#30':"Count"'R#10':"'L'"
	    HEADING H1:H2
		SELECT idx To idxList
		LOOP WHILE READNEXT KEY keyname,id FROM idxList DO
			IF keyname = lastkey THEN
				keyCount+=1
			END ELSE
				IF keyCount > 0 THEN PRINT FMT(lastkey,'L#30'):keyCount'R#10'
				lastkey = keyname
				keyCount=1
			END
		REPEAT
		IF keyCount > 0 THEN PRINT FMT(lastkey,'L#30'):keyCount'R#10'
	END ELSE
	H1="Indexes defined on ":@FILENAME:" 'CLTCLL'"
    H2="Attribute"'L#20':"IndexName"'L#20':"Typ MS Defn":"'L'"
    HEADING H1:H2
	Indexes = INDICES(%SourceFileObj)
	IdxCount = DCOUNT(Indexes,@AM)
	FOR I = 1 TO IdxCount
	 IndexDetails=INDICES(%SourceFileObj,Indexes<I>)
	 PRINT FMT(IndexDetails<9>,'L#20'):FMT(Indexes<I>,'L#20'):FMT(IndexDetails<1,1>,'L#4'):FMT(IndexDetails<6>,'L#3'):IndexDetails<2>[1,30]
	 If LEN(IndexDetails<2>) > 30 THEN
	 	FOR i = 30 to LEN(IndexDetails<2>) STEP 30 
	  		PRINT SPACE(47):FMT(IndexDetails<2>[i,i+30],'L#30')
	  	NEXT i
	 END
	NEXT I
	END
}

ClassMethod LISTPEQS()
{
#define HD                              HD^|"%SYS"|LANGC11
#define getJobStatus                    $$MVgetJobStatus^%SYS.MVSP
#define getJobStatusString              $$MVgetJobStatusString^%SYS.MVSP
#;
#; Get the spooler global name
#; 
	set SpoolGlobal = $$$PtrSpoolerGlobal
	if (($g(@SpoolGlobal@("FQ00000000","CREATE_T"))="")&&($g(@SpoolGlobal@("MVNEXTJOBNUMBER"))="")) { Q:$$SpoolCommandNEWTAB2^%SYS.MVSP("",1,"",1,0)}
#;
#; Check if we're putting in a filter for the account name.
#; This means the first operand will be "xxx" , including the quotes. The D3 document specifies
#; single quotes, the jBASE implementation only allows double quotes, we'll allow either.
#;
#; Note we can't use %MVCommandLine because that will have any quote characters removed.
#;
	set accname="" , wordn = 1  , cmd = $ZSTRIP(%MVLineNoVerb,"<=>W") , wordc = $l(cmd," ")
    if (wordn<=wordc) {
        set acc=$p(cmd," ",wordn), acc1=$e(acc) , accl=$e(acc,$l(acc))
        set:((acc1="""")||(acc1="'"))&&((accl="""")||(accl="'")) accname=$e(acc,2,$l(acc)-1),wordn=wordn+1
    }
#;
#; Check if we're going to restrict the output to certain job numbers.
#;
    set jobFrom=0,jobTo=999999999
    if (wordn<=wordc) {
        set p2=$p(cmd," ",wordn)                                				// Get second part of the command line
        set:(p2?1N.N) (jobFrom,jobTo)=p2                						// Single spooler form queue number
        set:(p2?1N.N1"-"1N.N) jobFrom=$p(p2,"-",1),jobTo=$p(p2,"-",2)           // Range of form queue number
    }
#;
#; Extract all the () options
#;
    set options=$p(cmd," ",wordc)
    set:'($e(options)="(") options=""                       					// Last token must end in "(" for it to be an option
    set optionA=$f(options,"A"), optionC=$f(options,"C"), optionF=$f(options,"F"),optionN=$f(options,"N")
#;
#; If option (A) used, then only check for this account name
#;
    set:optionA accname=$G($$$NAMESPACENames($namespace))                       	// Filter for this account name only
    set accnameF=$l(accname)                                        			// Makes it easy to see if there is an account name filter
#;
#; Build a list of columns we will display. The list is in the format "Column Name,Width,Description"
#;
    set columns = ""
    set $MV(columns, -1) = "JOBNO,5,#"
    set $MV(columns, -1) = "STATUS,9,STATUS"
    set $MV(columns, -1) = "COPIES,3,CP"
    set $MV(columns, -1) = "FORMQNUMBER,3,FO"
    set:optionN $MV(columns, -1) = "FORMQNAME,15,FORM QUEUE"
    set $MV(columns, -1) = "PAGES,6,PAGES"
    set $MV(columns, -1) = "CREATED,19,CREATED"
    set $MV(columns, -1) = "ACCOUNT,20,ACCT"
#;
#; Build up a header to be displayed.
#;
    set header="PRINTER LIST ELEMENTS                  'D' Page 'PLL'"
    set header2 = "", columnsCount=$l(columns,$MVam), header2Pos=1
    for columnsNext=1:1:columnsCount {
	    set nxt=$MV(columns,columnsNext), 		
	    	$e(header2,header2Pos)=$p(nxt,",",3),
	    	header2Pos = header2Pos + $p(nxt,",",2)
    }
    s header = header _ header2 _ "'L'"
    do $$$HD(header)
#;
#; If the (F) option was used, we'll sort by form queue.
#;
    set (qcount,pages) = 0
    if (optionF) {
        set keyFQ = $ORDER(@SpoolGlobal@("FQ")) , keyFQL = 1
optionFAgain
        if ($e(keyFQ,1,2)'="FQ") goto End
            set displayFQ=1
    } Else {
	    set keyFQ="" , keyFQL=0 , displayFQ = 0
    }
#;
#; Scan through all the print jobs, display as appropraite, selecting via filters.
#;
    set jobNumber = $ORDER(@SpoolGlobal@(""))
    while (jobNumber?1N.N) {
        #;
        #; Check the account name , form queue and job number filters.
        #;
        if ($$$getJobStatus(SpoolGlobal,jobNumber)'="") {       // Do consistency check
            if (jobNumber'<jobFrom)&&(jobNumber<=jobTo) {
                set thisaccname=$g(@SpoolGlobal@(jobNumber,"ACCOUNT")),thisfqname=$g(@SpoolGlobal@(jobNumber,"FQNAME"))
                if (('accnameF)||(thisaccname=accname))&&(('keyFQL)||(thisfqname=keyFQ)) {
                    Set pagesThis=$g(@SpoolGlobal@(jobNumber,"PAGES"))
                    #;
                    #; Write details for this job unless the (C) option specified.
                    #;
                    if ('optionC) {
	                    set line="", linepos = 1
	                    for columnsNext=1:1:columnsCount {
		                    s nxt=$MV(columns,columnsNext),field=$p(nxt,",",1),width=$p(nxt,",",2)
		                    if (field="JOBNO") {
			                    s data=jobNumber
		                    } elseif (field="STATUS") {
                                s data=$$$getJobStatusString(jobNumber)
		                    } elseif (field="COPIES") {
                                s data=$g(@SpoolGlobal@(jobNumber,"COPIES"))
		                    } elseif (field="FORMQNUMBER") {
                                s data=($e($g(@SpoolGlobal@(jobNumber,"FQNAME")),3,*)+0)
		                    } elseif (field="FORMQNAME") {
                                s internalname=$g(@SpoolGlobal@(jobNumber,"FQNAME")),data=$g(@SpoolGlobal@(internalname,"NAME"))
		                    } elseif (field="PAGES") {
                                s data=pagesThis
		                    } elseif (field="CREATED") {
                                s data=$ZDATETIME($g(@SpoolGlobal@(jobNumber,"CREATE_T")),7,2)
		                    } elseif (field="ACCOUNT") {
                                s data=thisaccname
		                    } else {
			                    s data = ""
		                    }
		                    s $e(line,linepos) = data , linepos = linepos + width
	                    }
	                    s line=$ZSTRIP(line,">W")
                        #;
                        #; Display the queue name if this is the first 
                        #; job to be displayed for a new form queue
                        #;
                        if (displayFQ) {
                            MVP:qcount !                        // Display an extra blank line but NOT on the first time
                            MVP "Form queue "_($e(keyFQ,3,*)+0),!
                            set displayFQ=0
                        }
                        MVP line,!
                    }
                    Set qcount=qcount+1, pages=pages+pagesThis
                }
            }
        }
        set jobNumber = $ORDER(@SpoolGlobal@(jobNumber))
    }
    #;
    #; If using option (F), sort by the next form queue.
    #;
    if (optionF) {
        set keyFQ = $ORDER(@SpoolGlobal@(keyFQ))
        goto optionFAgain
    }
End
    MVP !,qcount_" queue elements listed. "_pages_" pages in use.",!
}

}
