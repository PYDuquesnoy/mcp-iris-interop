/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The <class>%CSP.XMLSQL</class> accepts an SQL statement in the incoming URL
/// and executes it as a Dynamic SQL query.  The results are returned in an
/// XML format that corresponds to the MS XML-SQL Server format. See:<br>
/// <br>
/// <a href=" http://msdn.microsoft.com/msdnmag/issues/0300/sql/default.aspx"> http://msdn.microsoft.com/msdnmag/issues/0300/sql/default.aspx</a><br>
/// <br>
/// There are 3 formats that can be specified using the FOR XML command:
/// <br>
/// <ul>
/// <li><b>RAW</b> - Return &lt;row/&gt; elements with columns as attributes.</li>
/// <li><b>AUTO</b> - Return the data in an XML tree structure.</li>
/// <li><b>EXPLICIT</b> - It is a pretty complex version of AUTO.</li>
/// </ul>
/// <br>
/// The DTD can also be requested using the <code>FOR XML format, DTD</code>. For example:<br>
/// <pre>
/// &lt;!DOCTYPE root [
/// &lt;!ELEMENT root (row)*&gt;
/// &lt;!ELEMENT row (#PCDATA)&gt;
/// &lt;!ATTLIST row
/// CustomerID CDATA #IMPLIED
/// OrderID CDATA #IMPLIED
/// OrderDate CDATA #IMPLIED&gt;
/// ]>
/// </pre>
/// <br>
Class %CSP.XMLSQL Extends %CSP.Page [ Not ProcedureBlock, System = 3 ]
{

/// Override PRIVATE from %CSP.Page
Parameter PRIVATE = 1;

/// Override ENCODED from %CSP.Page
Parameter ENCODED = 2;

/// The <method>OnPreHTTP()</method> is called by the CSP dispatcher before the HTTP
/// headers have been sent.  Here, we prepare the Dynamic SQL query and set the content
/// type to text/xml.
ClassMethod OnPreHTTP() As %Boolean
{
 New sql,i,x

 #; Grab the SQL statement
 Set sql=%request.Get("SQL")
 If sql="" Set %response.Status="400 Bad Request" Quit 0

 #; Strip off the 'FOR XML AUTO' since our SQL parser won't understand it
 Set x="FOR XML AUTO",i=$F($ZCVT(sql,"u"),x)
 If i>0 Set sql=$E(sql,1,i-$L(x)-1)_$E(sql,i,$L(sql))

 #; Prepare the query
 Set rs=##class(%ResultSet).%New("%DynamicQuery.SQL")
 Set %sc=rs.Prepare(sql)

 #; Set the content-type
 If $$$ISOK(%sc) Set %response.ContentType="text/xml"

 Quit 1
}

/// The <method>OnPage()</method> is called by the CSP dispatcher to generate the
/// page content.  For XMLSQL, we loop across the ResultSet and output the contents
/// as XML.
ClassMethod OnPage() As %Status
{
 New rows,i

 If $$$ISERR(%sc) Quit %sc

 #; Collect the row information
 Set rows=rs.GetColumnCount()
 For i=1:1:rows Set rows(i)=rs.GetColumnName(i)

 Write "<?xml version=""1.0""?>",$C(13,10)
 Write "<root>",$C(13,10)

 Do rs.Execute()
 For  Quit:'rs.Next()  Do
 . Write "<row "
 . For i=1:1:rows Write ..EscapeHTML(rows(i)),"=""",..EscapeHTML(rs.GetData(i)),""" "
 . Write "/>",$C(13,10)

 Write "</root>",$C(13,10)

 Quit $$$OK
}

/// The <method>OnPostHTTP()</method> is called by the CSP dispatcher after the page
/// content has been sent.  We use it here to clean up the ResultSet
ClassMethod OnPostHTTP()
{
 If $get(rs,$$$NULLOREF)'=$$$NULLOREF Do rs.Close()
 Quit
}

/// Process the XML SQL extras from the SQL statement.  The mode is as follows:<br>
/// <br>
/// <ul>
/// <li><b>0</b> - Default XML-SQL mode</li>
/// <li><b>1</b> - Oracle XML-SQL mode</li>
/// </ul>
/// <br>
ClassMethod PreProcessSQL(sql As %String, ByRef args As %String, mode As %Integer, ByRef xmlmode As %String) As %String
{
 New ctx,result,token,done
 Set result="",xmlmode="",done=0,args=0
 Kill modectx
 Do ..TkInit(sql,.ctx)
 For  Do  Quit:done
 . If 0=..TkToken(.ctx,.token) Set done=1 Quit
 . If token?1"{@".e1"}",mode=1 Do  ; handle Oracle syntax
 . . Set args($I(args))=$E(token,3,$L(token)-1)
 . . Set token="?"
 . If token="FOR",..TkIsNextToken(.ctx,"XML",1) Do  Quit:done
 . . Do ..TkSkipWhite(.ctx),..TkToken(.ctx,.token)  ; Get the 'XML' identifier
 . . For  Do  Quit:done  Quit:token'=","
 . . . Do ..TkSkipWhite(.ctx)
 . . . If 0=..TkToken(.ctx,.token) Set done=1 Quit
 . . . Set:xmlmode'="" xmlmode=xmlmode_"," Set xmlmode=xmlmode_$ZCVT(token,"u")
 . . . If 0=..TkToken(.ctx,.token) Set done=1 Quit
 . . . Do ..TkSkipWhite(.ctx)
 . Set result=result_token
 Quit result
}

ClassMethod TkInit(src As %String, ByRef ctx As %List) [ Internal ]
{
 Set ctx=$LB(1,src)
 Quit
}

ClassMethod TkToken(ByRef ctx As %List, ByRef token As %String) As %Boolean [ Internal ]
{
 New c,p,src,i
 Set p=$LI(ctx,1),src=$LI(ctx,2),token=""
 If p'<$L(ctx) Quit 0  ; End of string
 Set c=$E(src,p),p=p+1
 Do 
 . If """'"[c Do  Quit
 . . Set i=c For  Set token=token_c,c=$E(src,p) Quit:(i="")!(p>$L(src))  Do:c=i  Set p=p+1
 . . . If p<$L(src),$E(src,p+1)=i Set token=token_c,c=$E(src,p+1),p=p+1
 . . . Else  Set i=""
 . If $C(9,32)[c Do  Quit
 . . For  Set token=token_c,c=$E(src,p)  Quit:$C(9,32)'[c  Set p=p+1
 . If $C(13)=c Do  Quit
 . . Set token=c If $E(src,p)=$C(10) Set token=token_$C(10),p=p+1
 . If c="{" Do  Quit
 . . Set i=0
 . . For  Set token=token_c,i=i+$S(c="{":1,c="}":-1,1:0),c=$E(src,p)  Quit:(i=0)!(p'<$L(src))  Set p=p+1
 . If c?1p Do  Quit
 . . For  Set token=token_c,c=$E(src,p) Quit:(c'?1p)!("{}"_$c(32,9,10,13)[c)  Set p=p+1
 . If c?1a Do  Quit
 . . For  Set token=token_c,c=$E(src,p) Quit:c'?1an  Set p=p+1
 . For  Set token=token_c,c=$E(src,p) Quit:",""'{"_$c(32,9,10,13)[c  Set p=p+1
 Set $LI(ctx,1)=p
 Quit $L(token)
}

ClassMethod TkSkipWhite(ByRef ctx As %List) [ Internal ]
{
 New p,src
 Set p=$LI(ctx,1),src=$LI(ctx,2)
 For  Quit:p'<$L(src)  Quit:$C(32,9,10,13)'[$E(src,p)  Set p=p+1
 Set $LI(ctx,1)=p
 Quit
}

ClassMethod TkIsNextToken(ByRef ctx As %List, token As %String, skipwhite As %Boolean, nocase As %Boolean = 1) As %Boolean [ Internal ]
{
 New p,src,try
 Set p=$LI(ctx,1),src=$LI(ctx,2)
 For  Quit:p'<$L(src)  Quit:$C(32,9)'[$E(src,p)  Set p=p+1
 Set try=$E(src,p,p+$L(token)-1)
 If nocase Set try=$ZCVT(try,"u"),token=$ZCVT(token,"u")
 Quit (try=token)
}

ClassMethod ResolveElementName(expr As %String, element, AssumeName) As %String
{
 If 'AssumeName,expr?1"{@"1.e1"}" Set AssumeName=1,expr=$E(expr,3,$L(expr)-1)
 If 'AssumeName Quit expr  ; Just an expression
 If element.IsDefined(expr) Do  Quit expr
 . Set expr=element.GetAttribute(expr)
 . Set expr=$$QuoteCSP^%cspQuote(expr)
 Quit "%request.Get("""_expr_""")"
}

}
