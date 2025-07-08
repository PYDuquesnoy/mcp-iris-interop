/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %CSP.WLD.Base Extends %CSP.Page [ Not ProcedureBlock, System = 3 ]
{

ClassMethod CSPAction()
{
 ; get application and page
 S PREVPAGE=$G(%Page)
 S %App=$ZCVT($P(%request.URL,"/",3,$L(%request.URL,"/")-1),"U")
 S %Page=$P($ZCVT(%request.PageName,"U"),".CSP")
 S %pageno=$G(%pageno)+1
 S %pgstack(%pageno)=$G(%Page)
 S %sessid=%session.SessionId
 ;d TRACE^%wld("Page "_%Page_" ; session = "_%sessid)
 ;
 Set %zzio=$IO
 ;
 ; run action script, if any
 ;
 If %request.IsDefined("cspaction",1) Do
 . New i,zzmethod,zzcls
 . If '(%request.IsEncrypted("cspaction",1)) Do  Quit
 . . ; Log error, user has put a cspaction tag in here
 . Set i=%request.Get("cspaction",1)
 . Set zzcls=$p(i,".",1,$l(i,".")-1),zzmethod=$p(i,".",$l(i,"."))
 . Set zzcls=$$$NormalizeClassname(zzcls)
 . Set $ZT="RunTrap"
 . Do $classmethod(zzcls,zzmethod)
 Use %zzio
 Quit
RunTrap ; Log error in method being run
 ; Check for <CLASS DOES NOT EXIST> and <METHOD DOES NOT EXIST> errors
 If $ZE["<CLASS DOES NOT EXIST>" Do
 . ; Log class does not exist error
 If $ZE["<METHOD DOES NOT EXIST>" Do
 . ; Log method does not exist error
 Use %zzio
 Quit
}

ClassMethod CSPpps1()
{
 Do ..CSPpop()
 D ..CSPXrequest()
 Do ..CSPAction()
 S redirected=$G(wldredirect)
 S BACKTRACK=0 ; reset here
 I PREVPAGE="" K Error
 ; RT+ 18 May 2001
 Kill wldNoTemplateRedir
 ; RT- 18 May 2001
 I $G(Error)'="",'$G(redirected),PREVPAGE'="" D  Q
 .S %response.ServerSideRedirect=PREVPAGE_".csp"
 . ;d TRACE^%wld("redirect="_%response.ServerSideRedirect)
 .; RT+ 18 May 2001
 .I $ZCVT(%request.Get("NoTemplate"),"U")="TRUE" D
 ..S wldNoTemplateRedir="true" ; this will end up in session object
 .; RT- 18 May 2001
 .S wldredirect=1
 Quit
}

ClassMethod CSPpps2()
{
 I $G(JUMP)'=""
 {
 N %jump
 S %jump=$ZCVT(JUMP,"L")
 S %jump=$P(%jump,".csp",1)
 S %jump=$P(%jump,".asp",1)
 S %jump=%jump_".csp"
 S %response.ServerSideRedirect=%jump
 K BACK,JUMP
 }
 I $G(BACK)'="" 
 {
 N %jump
 S %jump=$ZCVT($G(%pgstack(%pageno-1)),"L")_".csp"
 S %pageno=%pageno-2
 S %response.ServerSideRedirect=%jump
 K BACK,JUMP
 }

 S %zzx=$O(SETCOOKIE(""))
 N %val,%path,%expire,%pdays,%persist,%pdate
 While %zzx'=""
 {
 S %val=$G(SETCOOKIE(%zzx))
 S %path=$G(COOKIEPATH(%zzx))
 S %expire=$G(COOKIEEXPIRES(%zzx))
 S %pdays=""
 S %persist=$G(^%WLDPARAM(%App,"CookiesPersist"))
 I %persist="" S %pdays=1
 I %persist=0 S %cexpire=""
 I %persist=1 D
 .S %pdate=$G(^%WLDPARAM(%App,"CookieExpiryDate"))
 .S %pdays=$G(^%WLDPARAM(%App,"CookieExpiryPeriod"))
 .I %pdate'="" S %cexpire=$$INETDATE^%wlduta(%pdate_",43200") Q
 .I %pdays="" S %pdays=1
 S %path=$G(^%WLDPARAM(%App,"CookiePath"))
 I %path="" S %path="/"
 ;
 I %pdays'="" S %expire=$$INETDATE^%wlduta(($H+%pdays)_",43200")
 ;D %response.SetCookie(%zzx,%val)
 D %response.SetCookie(%zzx,%val,%expire,%path)
 S %zzx=$O(SETCOOKIE(%zzx))
 }
 K SETCOOKIE
 Quit
}

ClassMethod CSPpostp()
{
 S Warning=""
 ;d TRACE^%wld("about to stack")
 D ..CSPstack()
 Quit
}

ClassMethod Quit()
{
 S %session.EndSession="1"
 Quit
}

ClassMethod CSPpop()
{
 ; RT+ 18 May 2001
 Q:%session.Preserve=1  ; state-aware mode, so symbol table will be preserved
 ; RT- 18 May 2001
 ; recover previous state, update with request name/value pairs
 N %zzx,%ignore
 Set %ignore="~wldname~wldval~%zzx~%zzv~%response~%request~%session"
 Set %zzx=$Order(%session.Data(""))
 ;d TRACE^%wld("pop at"_$H)
 While %zzx'="" 
 {
 If ($TR(%zzx,"%.","")?1A.ANP),($E(%zzx,1,4)'="%CSP"),(%ignore'[("~"_%zzx_"~"))
 {
 M @%zzx=%session.Data(%zzx)
 }
 Set %zzx=$Order(%session.Data(%zzx))
 }
 Quit
}

ClassMethod CSPstack()
{
 ; RT+ 18 May 2001
 ;d TRACE^%wld("in stack")
 Q:%session.Preserve=1  ; state-aware mode, so symbol table will be preserved
 ; RT- 18 May 2001
 S %App=$ZCVT($P(%request.URL,"/",3,$L(%request.URL,"/")-1),"U")
 S %sessid=%session.SessionId
 ; save state to session object
 Kill %session.Data ; clear it out first
 N %zzx
 S %zzx=""
 If $G(%wldemulate)'="" 
 {
 ; use minimum list of WLD variables
 Set %zzx=$Order(%wldsave(""))
 While %zzx'="" 
 {
 If $E(%zzx,1,4)'="%CSP",%zzx'="%zzx",%zzx'="%request",%zzx'="%response",%zzx'="%session"
 {
 M %session.Data(%zzx)=@%zzx
 }
 Set %zzx=$Order(%wldsave(%zzx))
 }
 }
 Else
 {
 Set %zzx=$Order(@%zzx)
 While %zzx'="" 
 {
 If $E(%zzx,1,4)'="%CSP",%zzx'="%zzx",%zzx'="%request",%zzx'="%response",%zzx'="%session"
 {
 M %session.Data(%zzx)=@%zzx
 }
 Set %zzx=$Order(@%zzx)
 }
 }
 I $G(^%WLDPARAM(%App,"CSPSymbolTableTrace"))=1
 {
 K ^%WLDCSPST(%sessid)
 M ^%WLDCSPST(%sessid)=%session.Data
 }
 ;d TRACE^%wld("end of CSPstack")		
 Quit
}

ClassMethod CSPXrequest()
{
 ; update with request name/value pairs
 N %zzx,i,%type,%zzy
 Kill %KEY
 Set CRLF=$C(13,10)
 Set %zzx=$Order(%request.Data(""))
 While %zzx'="" 
 {
 S %zzy=%zzx
 If %zzx[".x" S %zzy=$P(%zzx,".x",1)_"(""x"")"
 If %zzx[".y" S %zzy=$P(%zzx,".y",1)_"(""y"")"
 If $TR(%zzy,"%.","")?1A.ANP
 {
 S @%zzy=%request.Data(%zzx,1)
 S %type=$P($G(%namemap(%zzy)),"~",2)
 ;D TRACE^%wld("field "_%zzy_" : type="_%type)
 S %KEY(%zzx)=%request.Data(%zzx,1)
 K SELECTED(%zzy)
 I %KEY(%zzx)'="",%type'="TEXTAREA" S SELECTED(%zzx,%KEY(%zzx))=""
 Set i=2
 While $D(%request.Data(%zzx,i))
 {
 If i=2
 {
 Kill %KEY(%zzx)
 Set %KEY(%zzx,1)=%request.Data(%zzx,1)
 }
 S %KEY(%zzx,i)=%request.Data(%zzx,i)
 I %KEY(%zzx,i)'="" S SELECTED(%zzx,%KEY(%zzx,i))=""
 Set i=i+1
 }
 I %type="TEXTAREA"
 {
 N %lno,%left,%i,%name,%count
 ;
 S %lno=0,%left=""
 S %name=%zzx
 K TEXTAREA(%name)
 S %count=$ZP(%KEY(%zzx,""))
 I %count="" D
 .S %KEY(%zzx,1)=%KEY(%zzx)
 .S %count=1
 F %i=1:1:%count D
 .;
 .N %txt,%new,%len2,%maxlen,CRLF
 .;
 .S %maxlen=15000
 .S CRLF=$C(13,10)
 .;
rtext3a	.;
 .I %KEY(%name,%i)'[CRLF D  Q
 ..S %txt=%KEY(%name,%i)
 ..I ($L(%left)+$L(%txt))>%maxlen D
 ...S %len2=%maxlen-$L(%left)
 ...S %new=%left_$E(%txt,1,%len2)
 ...S %lno=%lno+1
 ...S TEXTAREA(%name,%lno)=%new
 ...S %left="<CONTINUE>"_$E(%txt,%len2+1,$L(%txt))
 ..E  D
 ...S %left=%left_%txt
 .S %lno=%lno+1,%txt=$P(%KEY(%name,%i),CRLF,1),%KEY(%name,%i)=$P(%KEY(%name,%i),CRLF,2,255)
 .I ($L(%left)+$L(%txt))>%maxlen D
 ..S %len2=%maxlen-$L(%left)
 ..S %new=%left_$E(%txt,1,%len2)
 ..S TEXTAREA(%name,%lno)=%new
 ..S %left="<CONTINUE>"_$E(%txt,%len2+1,$L(%txt))
 ..I %KEY(%name,%i)'="" D
 ...S %lno=%lno+1
 ...S TEXTAREA(%name,%lno)=%left
 ...S %left=""
 .E  S TEXTAREA(%name,%lno)=%left_%txt,%left=""
 .G rtext3a
 ;
 I %left'="" S TEXTAREA(%name,%lno+1)=%left
 ;
 ; now delete blank records at the end
 ;
 I $D(TEXTAREA(%name)) D
 .S %lno=""
 .F  S %lno=$O(TEXTAREA(%name,%lno),-1) Q:%lno=""  Q:TEXTAREA(%name,%lno)'=""  K TEXTAREA(%name,%lno) ;***
 .S TEXTAREA(%name)=%lno
 }
 Set %zzx=$Order(%request.Data(%zzx))
 }
 }
 K COOKIE
 Set %zzx=%request.NextCookie("")
 While %zzx'="" 
 {
 Set COOKIE(%zzx)=%request.GetCookie(%zzx)
 Set %zzx=%request.NextCookie(%zzx)
 }

 K NoTemplate
 I $G(%request.Data("NoTemplate",1))'="" S NoTemplate="TRUE"
 I $G(%session.Data("wldNoTemplateRedir"))'=""!($G(wldNoTemplateRedir)'="")
 {
 S NoTemplate="TRUE"
 Kill wldNoTemplateRedir
 Kill %session.Data("wldNoTemplateRedir")
 }
 Quit
}

ClassMethod CSPXReturn(%return)
{
 ; Break up %return string and send back as separate JavaScript Writes
 ;
 N %buf,%command,%left,%right
 ;
 S %buf=%return
 ;d TRACE^%wld("return="_%return)
 F  D  Q:%buf=""
 .S %command=$P(%buf,"&",1)
 .S %buf=$P(%buf,"&",2,255)
 .S %left=$P(%command,"=",1)
 .S %right=$P(%command,"=",2,255)
 . i %left[".value" D
 . . s %left=$P(%left,".",4)
 .I $E(%right,1)'=":" S %right="'"_%right_"'"
 .I %left="Error" D
 ..S %command="alert("_%right_")"
 .I $D(%namemap(%left)) D
 ..N %type,%jsref
 ..S %command=""
 ..S %type=$P(%namemap(%left),"~",2)
 ..S %jsref=$P(%namemap(%left),"~",1) ;d TRACE^%wld("jsref="_%jsref) k ^%WLDTRACE("namemap") M ^%WLDTRACE("namemap")=%namemap
 ..;
 ..I %type'="","TEXT~PASSWORD~SUBMIT"[%type D  Q
 ...S %left=%jsref_".value"
 ...S %command=%left_"="_%right
 ..;
 ..I %type="RADIO" D  Q
 ...N %elno,%maxel
 ...S %maxel=$P(%namemap(%left),"~",3)
 ...I %maxel>0 D
 ....S %elno=$G(%namemap(%left,$P(%right,"'",2)))
 ....S %command=%jsref_"["_%elno_"].checked=true"
 ...E  D
 ....S %command=%jsref_".checked=true"
 ...;D TRACE^%wld("command = "_%command)
 ...&html<#(%command)# ;>
 ..;
 ..I %type="CHECKBOX" D  Q
 ...N %elno,%maxel,%bool
 ...S %maxel=$P(%namemap(%left),"~",3)
 ...I %maxel>0 D
 ....N %value
 ....S %value=""
 ....F  S %value=$O(%namemap(%left,%value)) Q:%value=""  D
 .....S %elno=$G(%namemap(%left,%value))
 .....S %bool="false" I $D(SELECTED(%left,%value)) S %bool="true"
 .....S %command=%jsref_"["_%elno_"].checked="_%bool
 .....&html<#(%command)# ;>
 ...S %command="" ; make it fall through gracefully at end of loop
 ...E  D
 ....S %command=%jsref_".checked=true"
 ..;
 ..I %type="TEXTAREA" D  Q
 ...N %lno,%lcnt,%miss,%i,%txt
 ...S %lno="",%lcnt=0,%txt=""
 ...F  S %lno=$O(TEXTAREA(%left,%lno)) Q:%lno=""  D
 ....S %miss=%lno-%lcnt-1
 ....I %miss>0 F %i=1:1:%miss S %txt=%txt_"\r\n"
 ....S %txt=%txt_TEXTAREA(%left,%lno)_"\r\n"
 ....S %lcnt=%lno
 ...S %command=%jsref_".value='"_%txt_"'"
 ..;
 ..I %type="SELECT" D  Q
 ...N %no,%text,%value,%max
 ...S %command="NoOfOptions = "_%jsref_".length"
 ...&html<#(%command)# ;>
 ...S %no="",%max=0
 ...F  S %no=$O(LIST(%left,%no)) Q:%no=""  D
 ....S %max=%max+1
 ....S %text=LIST(%left,%no)
 ....I %text["~" D
 .....S %value=$P(%text,"~",2)
 .....S %text=$P(%text,"~",1)
 ....E  D
 .....S %value=$G(VALUE(%left,%no))
 ....; add extra option
 ....S %command="if ("_%no_" > NoOfOptions) { var NewOpt = new Option("""_%text_""") ; "_%jsref_".options["_(%no-1)_"] = NewOpt }"
 ....&html<#(%command)# ;>
 ....;
 ....S %command=%jsref_".options["_(%no-1)_"].text='"_%text_"'"
 ....&html<#(%command)# ;>
 ....S %command=%jsref_".options["_(%no-1)_"].value='"_%value_"'"
 ....&html<#(%command)# ;>
 ....S %command=%jsref_".options["_(%no-1)_"].selected = false ;"
 ....&html<#(%command)# ;>
 ....I %text'="",$D(SELECTED(%left,%text)) D
 .....S %command=%jsref_".options["_(%no-1)_"].selected = true ;"
 .....&html<#(%command)# ;>
 ....I %value'="",$D(SELECTED(%left,%value)) D
 .....S %command=%jsref_".options["_(%no-1)_"].selected = true ;"
 .....&html<#(%command)# ;>
 ...S %command="if ("_%max_" < NoOfOptions) { for (i = "_%max_" ; i  < NoOfOptions ; i = i + 1) { "_%jsref_".options["_%max_"] = null } }"
 ...&html<#(%command)# ;>
 ...S %command="" ; make it fall through gracefully at end of loop
 .I %command'="" &html<#(%command)# ;>
 Q
 ;
}

ClassMethod GridDown(tablename, currentRow, absTopRow)
{
 ; gone down beyond bottom of table - fetch next row
 ; and shuffle up table
 N %d,WantRow,d
 ;d TRACE^%wld("in GridDown in superclass")
 ; save the inputs to stop the symbol table pop corrupting them
 S ^WLDTEMP($J)=tablename_"~"_currentRow_"~"_absTopRow
 Do ..CSPpop()
 ; now recover the inputs
 S d=^WLDTEMP($J)
 S tablename=$P(d,"~",1)
 S currentRow=$P(d,"~",2)
 S absTopRow=$P(d,"~",3)
 K ^WLDTEMP($J)
 ;
 S %d=$G(GRID(tablename))
 S %maxcol=$P(%d,"~",1)
 S %maxrow=$ZP(GRID(tablename,"data",""))
 S WantRow=absTopRow+currentRow+1
 ;
 ;
 ; run user method if defined - the converter will have built the
 ; following standardised dispatch call
 ;
 D ..wldGridActionDOWN()
 I WantRow>%maxrow Q  ; last row already reached
 ;
 ; shift table up one row
 ;
 ;write "alert('got here!') ;",!
 write "for (irow = 0; irow < "_currentRow_"; irow++)",!
 write "     {",!
 write "         for (colno = 0; colno < "_%maxcol_"; colno++)",!
 write "         {",!
 write "              oval = document.all."_tablename_"d.rows(irow+1).cells(colno).innerHTML ;",!
 write "              document.all."_tablename_"d.rows(irow).cells(colno).innerHTML = oval ;",!
 write "         }",!
 write "     }",!
 F %i=1:1:%maxcol D
 . S %value=$G(GRID(tablename,"data",absTopRow+currentRow+1,%i))
 . write "document.all."_tablename_"d.rows("_currentRow_").cells("_(%i-1)_").innerHTML='"_%value_"' ;",!
 write "AbsTopRow++ ; ",!
 ;
 ;
 I $G(Error)'="" D
 . write "alert('"_Error_"') ;",!
 . kill Error
 ;
 D ..CSPstack()
 Q
}

ClassMethod GridUp(tablename, currentRow, absTopRow)
{
 ; gone up beyond top of table - fetch previous row
 ; and shuffle down table
 ;
 N %d,WantRow,d
 ; save the inputs to stop the symbol table pop corrupting them
 S ^WLDTEMP($J)=tablename_"~"_currentRow_"~"_absTopRow
 Do ..CSPpop()
 ; now recover the inputs
 S d=^WLDTEMP($J)
 S tablename=$P(d,"~",1)
 S currentRow=$P(d,"~",2)
 S absTopRow=$P(d,"~",3)
 K ^WLDTEMP($J)
 ;
 S %d=$G(GRID(tablename))
 S %maxcol=$P(%d,"~",1)
 S %maxrow=$ZP(GRID(tablename,"data",""))
 S WantRow=absTopRow-1
 ;
 ;
 ; run user method if defined - the converter will have built the
 ; following standardised dispatch call
 ;
 D ..wldGridActionUP()
 I WantRow<1 Q  ; top row already reached
 ;
 ; shift table down one row
 ;
 write "for (irow = document.all."_tablename_"d.rows.length-1; irow >0 ; irow--)",!
 write "     {",!
 write "         for (colno = 0; colno < "_%maxcol_"; colno++)",!
 write "         {",!
 write "              oval = document.all."_tablename_"d.rows(irow-1).cells(colno).innerHTML ;",!
 write "              document.all."_tablename_"d.rows(irow).cells(colno).innerHTML = oval ;",!
 write "         }",!
 write "     }",!
 F %i=1:1:%maxcol D
 . S %value=$G(GRID(tablename,"data",absTopRow-1,%i))
 . write "document.all."_tablename_"d.rows("_currentRow_").cells("_(%i-1)_").innerHTML='"_%value_"' ;",!
 write "AbsTopRow-- ; ",!
 ;
 ;
 I $G(Error)'="" D
 . write "alert('"_Error_"') ;",!
 . kill Error
 ;
 D ..CSPstack()
 Q
}

ClassMethod GridCloseEdit(tablename, CurrentRow, col, value, userMethod)
{
 ; push value back into GRID array
 ;
 N d
 ; first recover state to retrieve GRID
 ; need to protect the input parameters though
 S ^WLDTEMP($J)=tablename_"~"_CurrentRow_"~"_col_"~"_value
 Do ..CSPpop()
 ; now reinstate the inputs
 S d=^WLDTEMP($J)
 S tablename=$P(d,"~",1)
 S EditedRow=$P(d,"~",2)
 S EditedCol=$P(d,"~",3)+1
 S value=$P(d,"~",4)
 K ^WLDTEMP($J)
 ;
 ; run user method if defined - the converter will have built the
 ; following standardised dispatch call
 ;
 D ..wldGridActionEDIT()
 ;
 ;update the grid and save it away again
 S GRID(tablename,"data",EditedRow,(EditedCol+1))=value
 ;
 I $G(Error)'="" D
 . write "alert('"_Error_"') ;",!
 . kill Error
 ;
 D ..CSPstack()
 Q
}

ClassMethod GridSelectRow(tablename, CurrentRow, AbsTopRow, userMethod)
{
 ; push value back into GRID array
 ;
 N d,%maxcol,%i,%value
 ; first recover state to retrieve GRID
 ; need to protect the input parameters though
 S ^WLDTEMP($J)=tablename_"~"_CurrentRow_"~"_AbsTopRow
 Do ..CSPpop()
 ; now reinstate the inputs
 S d=^WLDTEMP($J)
 S tablename=$P(d,"~",1)
 S CurrentRow=$P(d,"~",2)
 S AbsTopRow=$P(d,"~",3)
 K ^WLDTEMP($J)
 S SelectedRow=AbsTopRow+CurrentRow
 S d=$G(GRID(tablename))
 S %maxcol=$P(d,"~",1)
 ;
 ; run user method if defined - the converter will have built the
 ; following standardised dispatch call
 ;
 D ..wldGridActionSELECT()
 ;
 ; write back the row in case values have been modified by the user's process
 F %i=1:1:%maxcol D
 . S %value=$G(GRID(tablename,"data",SelectedRow,%i))
 . write "document.all."_tablename_"d.rows("_(CurrentRow)_").cells("_(%i-1)_").innerHTML='"_%value_"' ;",!
 ;
 I $G(Error)'="" D
 . write "alert('"_Error_"') ;",!
 . kill Error
 ;
 D ..CSPstack()
 Q
}

ClassMethod wldGridActionEDIT() [ Abstract ]
{
}

ClassMethod wldGridActionDOWN() [ Abstract ]
{
}

ClassMethod wldGridActionSELECT() [ Abstract ]
{
}

ClassMethod wldGridActionUP() [ Abstract ]
{
}

}
