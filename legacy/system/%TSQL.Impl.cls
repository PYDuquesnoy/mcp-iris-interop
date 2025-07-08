/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %apiXSQL

/// <P> Implementation of TSQL scalar and other functions not supported by SQL
Class %TSQL.Impl Extends %RegisteredObject [ System = 4 ]
{

/// <P> Implement CHARINDEX(tofind,findin[,startat])
ClassMethod CHARINDEX(ToFind As %String, FindIn As %String, StartAt As %Integer = 1) As %String [ SqlName = CHARINDEX, SqlProc ]
{
	// CHARINDEX(NULL,..,..) or CHARINDEX(..,NULL,..) = NULL
	If (ToFind="") || (FindIn="") {Quit ""}
	
	Set usefindin=$Case(FindIn,$C(0):"",:FindIn)
	Set usetofind=$Case(ToFind,$C(0):"",:ToFind)
	Set pos=$Find(usefindin,usetofind,StartAt)
	If pos=0 {
		Quit 0
	}
	Else {
		Quit pos-$Length(usetofind)
	}
}

/// <P> Implement DATALENGTH(item)
ClassMethod DATALENGTH(Item) As %Integer [ SqlName = DATALENGTH, SqlProc ]
{
	// DATALENGTH(NULL) = NULL
	If Item="" {Quit ""}
	
	// if it's a stream ..
	If ..IsStream(Item,.streamoref) {
		Quit streamoref.SizeGet()
	}
	
	// .. not a stream ..
	Else {
		Quit $Case(Item,$C(0):0,:$Length(Item))
	}
}

/// <P> Implement ZWITHDATETIME(item) to append a date of 1/1/1900 and/or a time of midnight to the item if necessary
ClassMethod ZWITHDATETIME(Item As %String) As %String [ SqlName = ZWITHDATETIME, SqlProc ]
{
	// ZWITHDATETIME(NULL) = NULL
	If Item="" {Quit ""}
	
	// ZWITHDATETIME("") = (default date + time)
	If Item=$Char(0) {Quit "1900-01-01 00:00:00"}
	
	// if there's no time ..
	If Item'[":" {
		
		// return it with the default time appended
		Quit Item_" 00:00:00"
	}
	
	// .. if there's no date ..
	ElseIf Item?1.N1":".E {
		
		// return it with the default date prepended
		Quit "1900-01-01 "_Item
	}
	
	// .. otherwise ..
	Else {
		
		// return it unchanged
		Quit Item
	}
}

/// <P> Implement ZREMAMPM(item) to remove the "AM" or "PM" if necessary
ClassMethod ZREMAMPM(Item) As %String [ SqlName = ZREMAMPM, SqlProc ]
{
	// ZREMAMPM(NULL) = NULL
	If Item="" {Quit ""}
	
	Set litem=$Length(Item)
	If litem<2 {Quit Item}
	
	Set ulast2=$ZCvt($Extract(Item,litem-1,litem),"U")
	If (ulast2="AM") || (ulast2="PM") {
		
		Set withoutampm=$ZStrip($Extract(Item,1,litem-2),">W")
		Set lwapsp=$Length(withoutampm," ")
		Set time=$Piece(withoutampm," ",lwapsp)
		
		If ulast2="PM" {
			If $Piece(time,":")<12 {Set $Piece(time,":")=+$Piece(time,":")+12}
		}
		Else {
			If $Piece(time,":")=12 {Set $Piece(time,":")="00"}
		}
		
		Set $Piece(withoutampm," ",lwapsp)=time
		
		Quit withoutampm
	}
	Else {
		Quit Item
	}
}

/// <P> Implement bitwiseOR
ClassMethod ZBITWISEOR(A, B) As %Integer [ SqlName = ZBITWISEOR, SqlProc ]
{
	// if either argument is NULL then return NULL
	If (A="")||(B="") {Quit ""}
	
	Quit $ZBoolean(+A,+B,7)
}

/// <P> Implement bitwiseAND
ClassMethod ZBITWISEAND(A, B) As %Integer [ SqlName = ZBITWISEAND, SqlProc ]
{
	// if either argument is NULL then return NULL
	If (A="")||(B="") {Quit ""}
	
	Quit $ZBoolean(+A,+B,1)
}

/// <P> Implement bitwiseXOR
ClassMethod ZBITWISEXOR(A, B) As %Integer [ SqlName = ZBITWISEXOR, SqlProc ]
{
	// if either argument is NULL then return NULL
	If (A="")||(B="") {Quit ""}
	
	Quit $ZBoolean(+A,+B,6)
}

/// <P> Translate a TSQL error code to a SQLCODE
ClassMethod ZCONVERRFROMTSQL(A) As %Integer [ SqlName = ZCONVERRFROMTSQL, SqlProc ]
{
	Quit A // stub
}

/// <P> Format a RAISERROR message with the given arguments
ClassMethod ZFORMATMESSAGE(Message, Args...) [ SqlName = ZFORMATMESSAGE, SqlProc ]
{
	Quit Message // stub
}

/// <P> Given a LIKE pattern and optional LIKE ESCAPE, return the corresponding COS pattern (SQL strings)
ClassMethod ZLIKETOCOSPATTERNS(LikePattern As %String, LikeEscape As %String = "") As %String [ SqlName = ZLIKETOCOSPATTERNS, SqlProc ]
{
	If (LikePattern="") || (LikeEscape="") {Quit ""}
	Set result=..ZLIKETOCOSPATTERN($S(LikePattern=$C(0):"",1:LikePattern),$S(LikeEscape=$C(0):"",1:LikeEscape))
	Quit $S(result="":$C(0),1:result)
}

/// <P> Given a LIKE pattern and optional LIKE ESCAPE, return the corresponding COS pattern (non-SQL strings)
ClassMethod ZLIKETOCOSPATTERN(LikePattern As %String, LikeEscape As %String = "") As %String [ CodeMode = expression ]
{
##class(%XSQL.Format).FlattenList(..ZLIKETOCOSPATTERNLIST(LikePattern,LikeEscape))
}

/// <P> Given a LIKE pattern and optional LIKE ESCAPE, return a list of top-level COS pattern elements
ClassMethod ZLIKETOCOSPATTERNLIST(LikePattern As %String, LikeEscape As %String = "") As %List [ Private, SqlName = ZLIKETOCOSPATTERNLIST, SqlProc ]
{
	// special case: is the pattern empty?
	If LikePattern="" {Quit $ListBuild("1""""")}
	// - if we pass that through the algorithm below we end up with a result which is also the empty string
	
    // search for special characters ("%", "_" and "[")
    Set result=""
    Set pos=1
    Set literal=""
    If $Length(LikeEscape)>1 {ZT}
    While 1 {

        // find next special characters
        Set posPercent=..Find(LikePattern,"%",pos)
        Set posUnderline=..Find(LikePattern,"_",pos)
        Set posLBrack=..Find(LikePattern,"[",pos)

        // branch on which comes first
        Set which=..CompareStringPos3(posPercent,posUnderline,posLBrack,$ListBuild(1,2,3))
        If which=0 {
            Set literal=literal_$Extract(LikePattern,pos,$Length(LikePattern))
            Quit  // quit the while loop
        }
	    
	    Set posEarliest=$Case(which,
	    	1:posPercent,
	    	2:posUnderline,
	    	3:posLBrack)
        
    	// if there's an escape before the special character ..
        If (LikeEscape'="") && (posEarliest>1) && ($Extract(LikePattern,posEarliest-1)=LikeEscape) {
	        
	        // add it to the literal, omitting the escape character itself
            Set literal=literal_$Extract(LikePattern,pos,posEarliest-2)_$Extract(LikePattern,posEarliest)
            
            // advance past the special character
            Set pos=posEarliest+1
        }
        
        // .. no escape before the special character ..
        Else {
	        
	        // add everything before the special character to the literal
            Set literal=literal_$Extract(LikePattern,pos,posEarliest-1)
            
            // advance past the special character
            Set pos=posEarliest+1
            
            // flush the literal to the result if necessary
            If literal'="" {
                Set result=result_$ListBuild("1"_##class(%XSQL.Format).QuoteCos(literal))
                Set literal=""
            }
            
            // if the special character was "%"..
	        If which=1 {
		        Set pattern=".E"
        	}
        	
        	// .. if the special character was "_" ..
        	ElseIf which=2 {
	        	Set pattern="1E"
        	}
        
        	// .. the special character was "[" ..
        	Else {
	        	Set rangetext=..ExtractRangeText(LikePattern,LikeEscape,.pos)
	        	Set pattern=..AnalyseRangePattern(rangetext,LikeEscape)
        	}

            // add the pattern to the result
            Set result=result_$ListBuild(pattern)
        }        
    }

    // flush the literal if necessary
    If literal'="" {
        Set result=result_$ListBuild("1"_##class(%XSQL.Format).QuoteCos(literal))
        Set literal=""
    }

    Quit result
}

/// <P> Given the position just after the "["
/// <P> Return with the position just after the "]" - or after the end of the string if there is no "]"
/// <P>
/// <P> Return the raw range text (with relevant escapes for "-" and the escape character itself still in place)
ClassMethod ExtractRangeText(LikePattern As %String, LikeEscape As %String, ByRef Pos As %Integer) As %String [ Private ]
{
	Set lLikePattern=$Length(LikePattern)
	
	// scan the pattern from Pos until we find an unescaped "]"
	Set result=""
	While Pos<=lLikePattern {
		
		Set c=$Extract(LikePattern,Pos),Pos=Pos+1
		
		// if it's an "]": quit the while loop
		If c="]" {Quit}
		
		// handle escapes
		Set escaped=0
		If c=LikeEscape {
			If Pos<=lLikePattern {
				Set c=$Extract(LikePattern,Pos),Pos=Pos+1
				Set escaped=1
			}
		}
		
		If escaped,(c="-") || (c=LikeEscape) {
			Set result=result_LikeEscape_c
		}
		Else {
			Set result=result_c
		}
	}
	
	Quit result
}

/// <P> Given RangeText with what appeared between [..] with the escapes for LikeEscape and "-" intact
/// <P> Return a COS pattern fragment which matches the range
ClassMethod AnalyseRangePattern(RangeText As %String, LikeEscape As %String) As %String [ Private ]
{
	$$$DEBUG("AnalyseRangePattern: RangeText="_##class(%XSQL.Format).QuoteCos(RangeText)_", LikeEscape="_##class(%XSQL.Format).QuoteCos(LikeEscape))
	
	Set lRangeText=$Length(RangeText)
	
	// a $List of $Lists, each inner list is either a single-character (1) or range (2)
	Set ranges=""
	
	// flags for A-Z, a-z, 0-9
	Set (flagU,flagL,flagN)=0
	
	// working character position in RangeText
	Set pos=1
	
	// scan RangeText ..
	While pos<=lRangeText {
		
		// first character in this section
		Set c1=$Extract(RangeText,pos),pos=pos+1
		
		// if it's the escape and there's at least a following character ..
		If c1=LikeEscape,pos<=lRangeText {
			
			// replace the character with the following one
			Set c1=$Extract(RangeText,pos),pos=pos+1
		}
		
		// if there's a following character, it's "-", and there's another character after that ..
		If pos<=lRangeText,$Extract(RangeText,pos)="-",pos+1<=lRangeText {
			
			// cross the "-"
			Set pos=pos+1
			
			// get the 3rd character in this section (not counting escape characters)
			Set c3=$Extract(RangeText,pos),pos=pos+1
			
			// if it's the escape and there's at least a following character ..
			If c3=LikeEscape,pos<=lRangeText {
				
				// replace the character with the following one
				Set c3=$Extract(RangeText,pos),pos=pos+1
			}
			
			// if it's a range which corresponds to a flag: set the flag
			If c1="a",c3="z" {Set flagL=1}
			ElseIf c1="A",c3="Z" {Set flagU=1}
			ElseIf c1="0",c3="9" {Set flagN=1}
			
			// .. otherwise add it to the list of range ..
			Else {Set ranges=ranges_$ListBuild($ListBuild(c1,c3))}
		}
		
		// .. not a range ..
		Else {
			
			// add single-character range
			Set ranges=ranges_$ListBuild($ListBuild(c1))
		}
	}
	
	$$$DEBUG("AnalyseRangePattern: flags="_$S(flagU:"U",1:"")_$S(flagL:"L",1:"")_$S(flagN:"N",1:""))
	$$$DEBUG("AnalyseRangePattern: ranges="_##class(%XSQL.Format).ListFormat(ranges))
	
	// convert flags to COS pattern term
	Set flagterm=""
	If flagU || flagL || flagN {
		Set flagterm="1"
		If flagU,flagL {Set flagterm=flagterm_"A"}
		ElseIf flagU {Set flagterm=flagterm_"U"}
		ElseIf flagL {Set flagterm=flagterm_"L"}
		If flagN {Set flagterm=flagterm_"N"}
	}
	
	// convert ranges to a comma-separated string of COS pattern terms
	Set rangepattern=""
	If ranges'="" {
		Set rangepattern=..RangeToPattern($List(ranges))
		For i=2:1:$ListLength(ranges) {
			Set rangepattern=rangepattern_","_..RangeToPattern($List(ranges,i))
		}
	}
	
	$$$DEBUG("AnalyseRangePattern: flagterm="_##class(%XSQL.Format).QuoteCos(flagterm)_", rangepattern="_##class(%XSQL.Format).ListFormat(rangepattern))
	
	// combine flags and range terms, as appropriate
	If flagterm="",rangepattern="" {Quit ""}
	ElseIf flagterm="" {Quit $Select($ListLength(ranges)=1:rangepattern,1:"1("_rangepattern_")")}
	ElseIf rangepattern="" {Quit flagterm}
	Else {Quit "1("_flagterm_","_rangepattern_")"}
}

ClassMethod RangeToPattern(Range As %List) As %String [ Private ]
{
	$$$ASSERT(Range'="")
	Set result="1"_##class(%XSQL.Format).QuoteCos($List(Range))
	If $ListLength(Range)>1 {
		For a=$Ascii($List(Range))+1:1:$Ascii($List(Range,2)) {
			Set result=result_",1"_##class(%XSQL.Format).QuoteCos($Char(a))
		}
		Set result="1("_result_")"
	}
	Quit result
}

/// <P> Look for LookIn in LookFor starting at StartLook (defaults to 1)
/// <P> If the string isn't found then 0 is returned
/// <P> If the string is found then the 1-based offset to the start of LookFor in LookIn is returned
ClassMethod Find(LookIn As %String, LookFor As %String, StartLook As %Integer = 1)
{
		Set dfpos=$Find(LookIn,LookFor,StartLook)
		If dfpos=0 {Quit 0} Else {Quit dfpos-$Length(LookFor)}
}

/// <P> N1-N3 are COS string positions, 1-based and 0 means not found
/// <P> If one of the positions is undisputedly earliest of the three its tag is returned
/// <P> otherwise return 0
ClassMethod CompareStringPos3(N1 As %Integer, N2 As %Integer, N3 As %Integer, Tags As %List) As %Integer [ Private ]
{
	If 'N1 {Quit ..CompareStringPos2(N2,N3,$List(Tags,2,3))}
	If 'N2 {Quit ..CompareStringPos2(N1,N3,$ListBuild($List(Tags),$List(Tags,3)))}
	If 'N3 {Quit ..CompareStringPos2(N1,N2,$List(Tags,1,2))}
	
	If N1<N2,N1<N3 {Quit $List(Tags)}
	If N2<N1,N2<N3 {Quit $List(Tags,2)}
	If N3<N1,N3<N2 {Quit $List(Tags,3)}
	
	Quit 0
}

/// <P> N1-N2 are COS string positions, 1-based and 0 means not found
/// <P> If one of the positions is undisputedly earlier its tag is returned
/// <P> otherwise return 0
ClassMethod CompareStringPos2(N1 As %Integer, N2 As %Integer, Tags As %List) As %Integer [ Private ]
{
	If 'N1,'N2 {Quit 0}
	
	If 'N1 {Quit $List(Tags,2)}
	If 'N2 {Quit $List(Tags)}
		
	If N1<N2 {Quit $List(Tags)}
	If N2<N1 {Quit $List(Tags,2)}
	
	Quit 0
}

/// <P> Implement STUFF(sourcestring,startpos,replacelength,replacestring)
ClassMethod STUFF(SourceString As %String, StartPos As %Integer, ReplaceLength As %Integer, ReplaceString As %String) As %String [ SqlName = STUFF, SqlProc ]
{
	// STUFF(...NULL...) = NULL
	If (SourceString="") || (StartPos="") || (ReplaceLength="") || (ReplaceString="") {Quit ""}
	
	// Canonical forms
	Set sourcestring=$Select(SourceString=$Char(0):"",1:SourceString)
	Set startpos=+StartPos
	Set replacelength=+ReplaceLength
	Set replacestring=$Select(ReplaceString=$Char(0):"",1:ReplaceString)
	
	// StartPos/ReplaceLength<0 => ""
	If (startpos<0) || (replacelength<0) {Quit $Char(0)}
	
	// StartPos>SourceString length => ""
	If startpos>$Length(sourcestring) {Quit $C(0)}
	
	Set result=$Extract(sourcestring,1,startpos-1)_replacestring_$Extract(sourcestring,startpos+replacelength,$Length(sourcestring))
	
	Quit $Select(result="":$Char(0),1:result)
}

/// <P> Implement ZRAND(scalefactor)
ClassMethod ZRAND(ScaleFactor As %Integer) As %Float [ CodeMode = expression, SqlName = ZRAND, SqlProc ]
{
$Random(ScaleFactor)/ScaleFactor
}

/// <P> PATINDEX for non-literal patterns
ClassMethod ZRPATINDEX(TsqlPattern As %String, Expr As %String) As %Integer [ SqlName = ZRPATINDEX, SqlProc ]
{
	// if the TSQL pattern begins with "%" ..
	If $Extract(TsqlPattern)="%" {
		Quit ..ZPATINDEXPN(..ZLIKETOCOSPATTERN($Extract(TsqlPattern,2,$Length(TsqlPattern)),""),Expr)	
	}
	
	// .. TSQL pattern doesn't begin with "%" ..
	Else {
		Quit ..ZPATINDEXFB(..ZLIKETOCOSPATTERN(TsqlPattern,""),Expr)		
	}
}

/// <P> PATINDEX for "%"+XXX+"%" patterns
ClassMethod ZRPATINDEXPLP(TsqlInnerPattern As %String, Expr As %String) As %Integer [ SqlName = ZRPATINDEXPLP, SqlProc ]
{
	// if the TSQL inner pattern includes wildcards ..
	If (TsqlInnerPattern["%") || (TsqlInnerPattern["_") {
		Quit ..ZPATINDEXPN(..ZLIKETOCOSPATTERN("%"_TsqlInnerPattern_"%",""),Expr)	
	}
	
	// .. inner pattern doesn't include wildcards ..
	Else {
		Quit Expr[TsqlInnerPattern // result is 0 or 1
	}
}

/// <P> PATINDEX for: percent literal - returns 0/position of literal
ClassMethod ZPATINDEXPL(LiteralPart As %String, Expr As %String) As %Integer [ SqlName = ZPATINDEXPL, SqlProc ]
{
	Set lExpr=$Length(Expr)
	Set posLiteral=lExpr-$Length(LiteralPart)+1
	If $Extract(Expr,posLiteral,lExpr)=LiteralPart {
		Quit posLiteral
	}
	Else {
		Quit 0
	}
}

/// <P> PATINDEX for: percent literal rest - 0/returns position of literal
ClassMethod ZPATINDEXPLR(LiteralPart As %String, CosPattern As %String, Expr As %String) As %Integer [ SqlName = ZPATINDEXPLR, SqlProc ]
{
	Set lLiteralPart=$Length(LiteralPart)
	Set lExpr=$Length(Expr)
	Set pos=1
	While 1 {
		Set npos=..Find(Expr,LiteralPart,pos)
		If npos=0 {Quit}
		Set pos=npos+lLiteralPart
		If $Extract(Expr,pos,lExpr)?@CosPattern {Quit}
	}
	Quit npos
}

/// <P> PATINDEX for: percent non-literal - returns 0/position of non-literal
ClassMethod ZPATINDEXPN(CosPattern As %String, Expr As %String) As %Integer [ SqlName = ZPATINDEXPN, SqlProc ]
{
	// compiler should catch this
	$$$ASSERT(CosPattern'="")
	
	Set lExpr=$Length(Expr)
	Set found=0
	For pos=1:1:lExpr {
		If $Extract(Expr,pos,lExpr)?@CosPattern {Set found=pos Quit}
	}
	Quit found
}

/// <P> PATINDEX for: underline(s) - returns 0/1
ClassMethod ZPATINDEXU(UnderlineCount As %Integer, Expr As %String) As %Integer [ CodeMode = expression, SqlName = ZPATINDEXU, SqlProc ]
{
$Length(Expr)=UnderlineCount
}

/// <P> PATINDEX for: underline(s) literal - returns 0/1
ClassMethod ZPATINDEXUL(UnderlineCount As %Integer, LiteralPart As %String, Expr As %String) As %Integer [ CodeMode = expression, SqlName = ZPATINDEXUL, SqlProc ]
{
(UnderlineCount<=$Length(Expr)) && ($Extract(Expr,UnderlineCount+1,$Length(Expr))=LiteralPart)
}

/// <P> PATINDEX for: underline(s) literal rest - returns 0/1
ClassMethod ZPATINDEXULR(UnderlineCount As %Integer, LiteralPart As %String, CosPattern As %String, Expr As %String) As %Integer [ CodeMode = expression, SqlName = ZPATINDEXULR, SqlProc ]
{
(UnderlineCount<=$Length(Expr)) && ($Extract(Expr,UnderlineCount+1,UnderlineCount+$Length(LiteralPart))=LiteralPart) && ($Extract(Expr,UnderlineCount+1+$Length(LiteralPart),$Length(Expr))?@CosPattern)
}

/// <P> PATINDEX for: literal - returns 0/1
ClassMethod ZPATINDEXL(LiteralPart As %String, Expr As %String) As %Integer [ CodeMode = expression, SqlName = ZPATINDEXL, SqlProc ]
{
Expr=LiteralPart
}

/// <P> PATINDEX for: literal rest - returns 0/1
ClassMethod ZPATINDEXLR(LiteralPart As %String, CosPattern As %String, Expr As %String) As %Integer [ CodeMode = expression, SqlName = ZPATINDEXLR, SqlProc ]
{
($Extract(Expr,1,$Length(LiteralPart))=LiteralPart) && ($Extract(Expr,$Length(LiteralPart)+1,$Length(Expr))?@CosPattern)
}

/// <P> PATINDEX for anything that isn't covered above (FB=fallback) - returns 0/1
/// <P> - will not give the correct result for a pattern beginning with "%"
ClassMethod ZPATINDEXFB(CosPattern As %String, Expr As %String) As %Integer [ CodeMode = expression, SqlName = ZPATINDEXFB, SqlProc ]
{
Expr?@CosPattern
}

/// <P> Implement FLOOR for COS context
ClassMethod FLOOR(Number As %String) As %Numeric [ CodeMode = expression ]
{
$Select('$isvalidnum(Number):"",Number[".":+$Piece(Number,".")-(Number<0),1:Number)
}

/// <P> Implement LEN for COS context
ClassMethod LEN(Str As %String) As %Integer [ CodeMode = expression ]
{
$Select(Str="":"",Str=$Char(0):0,1:$Length($ZStrip(Str,">W")))
}

/// <P> Implement SUBSTRING(item, start, length)
ClassMethod SUBSTRING(Item, Start, Length) As %String [ SqlName = SUBSTRING, SqlProc ]
{
	// SUBSTRING(... any NULL ...) = NULL
	If (Item="") || (Start="") || (Length="") {Quit ""}
	
	// if it's a stream ..
	If ..IsStream(Item,.streamoref) {
		If 'streamoref.MoveTo(Start) {Set result=""}
		Else {Set result=streamoref.Read(Length)}
	}
	
	// .. not a stream ..
	Else {
		Set result=$Case(Item,$C(0):"",:$Extract(Item,Start,Start+Length-1))
	}
	
	Quit $Select(result="":$C(0),1:result)
}

/// <P> Implement REPLACE(expr,old,new)
ClassMethod REPLACE(Expr As %String, Old As %String, New As %String) As %String [ SqlName = REPLACE, SqlProc ]
{
	// REPLACE(...NULL...) = NULL
	If (Expr="") || (Old="") || (New="") {Quit ""}
	
	Set useexpr=$Case(Expr,$C(0):"",:Expr)
	Set useold=$Case(Old,$C(0):"",:Old)
	Set usenew=$Case(New,$C(0):"",:New)
	
	If useold="" {Set result=Expr}
	Else {Set result=##class(%XSQL.Format).Replace(useexpr,useold,usenew)}
	
	Quit $Select(result="":$C(0),1:result)
}

ClassMethod ZPATTERNMATCH(Expr As %String, CosPattern As %String) As %Integer [ SqlName = ZPATTERNMATCH, SqlProc ]
{
	// ZPATTERNMATCH(...NULL...) = NULL
	If (Expr="") || (CosPattern="") {Quit ""}

	Quit $S($S(Expr=$C(0):"",1:Expr)?@$S(CosPattern=$C(0):"",1:CosPattern):1,1:0)
}

/// <P> Implement IFNULL(expr1,expr2[,expr3])
ClassMethod IFNULL(Expr1 As %String, Expr2 As %String, Expr3 As %String = "") As %String [ CodeMode = expression, SqlName = IFNULL, SqlProc ]
{
$Select(Expr1="":Expr2,1:Expr3)
}

/// <P> Is the given value a stream id?
/// <P> - if so: return 1 and set StreamOref
/// <P> - otherwise: return 0 and set StreamOref to $$$NULLOREF
ClassMethod IsStream(Value As %String, ByRef StreamOref) As %Boolean
{
	// initial default
	Set StreamOref=$$$NULLOREF
	
	// if it's an OREF (the new format) ..
	If $IsObject(Value) {
		Set StreamOref=Value
		Quit 1
	}
	
	// if it's a list with a stream class as the second item (the old format) ..
	Set $ZTrap="trap"
	Set result=$$$getClassType($$NormalizeClassname^%occName($ListGet(Value,2))) = $$$cCLASSCLASSTYPESTREAM
	Set $ZTrap=""
	If result {
		Set StreamOref=##class(%SerialStream).%Open(Value)
	}
	Quit result
	
	// trap for when Value is not a list
trap
	Set $ZTrap=""
	If $ZError'["<LIST>" {ZTrap $ZError}
	Quit 0
}

/// <P> Implement ROUND(number,length,function)
ClassMethod ROUND(Number As %Numeric, Length As %Integer, Function As %Integer) As %String [ SqlName = ROUND, SqlProc ]
{
	// ROUND(NULL,..,..) or ROUND(..,NULL,..) = NULL
	If (Number="") || (Length="") {Quit ""}
	
	Set usenumber=$Case(Number,$C(0):"",:Number)
	Set uselength=$Case(Length,$C(0):"",:Length)
	Quit +$$ROUND^%qarfunc(usenumber,uselength,Function)
	// - that "+" is very important ...
}

}
