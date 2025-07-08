/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The <CLASS>%CSP.Utils</CLASS> provides utilities for CSP.
/// %CSP.Utils is also a CSP page that displays the values of all the objects associated with this page.
Class %CSP.Utils Extends %CSP.Page [ Not ProcedureBlock, System = 3 ]
{

/// Override PRIVATE from %CSP.Page
Parameter PRIVATE = 1;

/// Override ENCODED from %CSP.Page
Parameter ENCODED = 0;

/// OnPage method for CSP page to display the values of all the objects associated with this page.
ClassMethod OnPage() As %Status
{
	Set $ZT="OnPageTrap"
	Do ..OnPageCSPROOT()
	Quit $$$OK
OnPageTrap	$$$SysLogError("%CSP.Utils","Error dumping objects")
	Quit $$$OK
}

/// Call this method to output as HTML the values of all the objects associated with this page.
/// This can be called from anywhere in your page as a debugging aid.
ClassMethod DisplayAllObjects() As %Boolean
{
	&html<
<table bgcolor="#000088" cols="2" width="100%" border="1" cellpadding="3">
<tr>
<td width="50%"> <nobr><font face="Verdana,Arial,Helvetica,sans-serif" color="white" size="+3"> 
<b>&nbsp;#(%response.GetText("","%CSP","ObjectInspector","CSP request object inspector"))#</b></font></nobr> </td>
</tr>
</table>
<br>
<table width="100%">
<tr>
<td width="66%"><font face="Verdana, Arial, Helvetica, sans-serif">
#(%response.GetText("","%CSP","InspectorDescription","This page inspects CSP server side objects when a request is processed. It shows all the public properties of %request, %session and %response objects, as well as tables of queries, CGI variables, cookies and streams stored inside %request object."))#
</font></tr>
</table>
<hr><font face="Verdana, Arial, Helvetica, sans-serif">
#(%response.GetText("","%CSP","InspectorVersion","Running on &lt;b&gt;%1&lt;/b&gt;",$ZV))#<br>
#(%response.GetText("","%CSP","InspectorNamespace","This CSP request is running in the namespace &lt;b&gt;%1&lt;/b&gt;",$namespace))#<br>
#(%response.GetText("","%CSP","InspectorProcess","The process that served this request has ID &lt;b&gt;%1&lt;/b&gt;",$J))#<br>
#(%response.GetText("","%CSP","InspectorUserRole",,$select($listget(%session.SecurityContext)="":"UnknownUser",1:$list(%session.SecurityContext)),$listget(%session.SecurityContext,3)))#<br>
#(%response.GetText("","%CSP","InspectorTime","The current time is (UTC) &lt;b&gt;%1&lt;/b&gt;",$zdt($ztimestamp)))#<br>
>
	Do ..dumpObject(%request,"%request Properties")
	Do ..dumpQueries(%request,"Queries",%response.GetText("","%CSP","InspectorQueries","These are the name-value pairs from the URL or form post"))
	Do ..dumpSet(%request,"CGI Variables","CgiEnv")
	Do ..dumpSet(%request,"Cookies","Cookie")
	Do ..dumpStreams(%request,"Streams")
	Do ..dumpObject(%session,"%session Properties")
	Do ..dumpMultidimentional("%session.Data","Session Data")
	Do ..dumpObject(%response,"%response Properties")
	Write !
}

/// OnPageCSPRoot method for CSP page to display the values of all the objects associated with this page.
ClassMethod OnPageCSPROOT() As %Boolean [ Internal, Private ]
{
	Write "<!--Inspects the contents of the CSP server side objects-->",!
	Do ..OnPageHTML()
	Write !
}

/// OnPageHTML method for CSP page to display the values of all the objects associated with this page.
ClassMethod OnPageHTML() As %Boolean [ Internal, Private ]
{
	Write "<html>",!
	Write "<body bgcolor=""#CCCCFF"">",!
	Do ..DisplayAllObjects()
	Write "</body>",!
	Write "</html>",!
}

/// Display an object as HTML
ClassMethod dumpObject(oref As %String, title As %String)
{
	New Class,i,Property,Row,Value
	Set Class=##class(%CompiledClass).%OpenId($classname(oref))
	If Class=$$$NULLOREF {
		&html<<hr><br><p><b>Unable to open definition of class #($classname(oref))# skipping this inspector section</b></p>>
		Quit
	}
	&html<<hr><br><p><b>#(title)#</b></p>
<table cellpadding="5" border="1" width="100%">
<tr><th align="left" width="20%"><font face="Verdana, Arial, Helvetica, sans-serif"><b>Property</b></font></th>
<th align="left"><font face="Verdana, Arial, Helvetica, sans-serif"><b>Contents</b></font></th></tr>>
	For i=1:1:Class.Properties.Count() {
		Set Property=Class.Properties.GetAt(i)
		If (Property.Private)||(Property.MultiDimensional)||(Property.Name="Key"&&($classname(oref)="%CSP.Session")) Continue
		Set Row=$g(Row)+1,Value=$PROPERTY(oref,Property.Name)
		&html<<tr bgcolor="#($S(Row#2:"#DDDDDD",1:"#FFFFFF"))#"><td><font face="Verdana, Arial, Helvetica, sans-serif">#(..DecodeData(Property.Name))#</font></td>
<td><font face="Verdana, Arial, Helvetica, sans-serif">#(..DecodeData(Value))#</font></td></tr>>
	}
	&html<</table><br>>
	Quit
}

/// Display query parameters from %request object
ClassMethod dumpQueries(oref As %String, Name As %String, help As %String = "")
{
	New Key,Value,Row,i,index

	&html<<hr><br><p><b>#(Name)#</b>>
	If (help '= "") {
		&html<- <i>#(help)#</i>>
	}
	&html<</p><table cellpadding="5" border="1" width="100%">
<tr><th align="left" width="20%"><font face="Verdana, Arial, Helvetica, sans-serif"><b>Name</b></font></th>
<th align="left"><font face="Verdana, Arial, Helvetica, sans-serif"><b>Index</b></font></th>
<th align="left"><font face="Verdana, Arial, Helvetica, sans-serif"><b>Value</b></font></th>
<th align="left"><font face="Verdana, Arial, Helvetica, sans-serif"><b>Encrypted</b></font></th></tr>>

	Set Key = oref.Next("")
	Set Row = 0
	If (Key="") {
		&html<<tr bgcolor="#DDDDDD"><td><font face="Verdana, Arial, Helvetica, sans-serif"><i>Empty</i></font></td></tr>>
	} Else {
		Set Key = oref.Next("")
		While (Key'="") {
			
			Set index=""
			Set Value=oref.NextIndex(Key,.index)
			While (index'="") {
				Set Row = Row + 1
				&html<<tr bgcolor="#($S(Row#2:"#DDDDDD",1:"#FFFFFF"))#"><td><font face="Verdana, Arial, Helvetica, sans-serif">#(..DecodeData(Key))#</font></td>
<td><font face="Verdana, Arial, Helvetica, sans-serif"><%=..DecodeData(index)%></font></td>
<td><font face="Verdana, Arial, Helvetica, sans-serif"><%=..DecodeData(Value)%></font></td>
<td><font face="Verdana, Arial, Helvetica, sans-serif"><%=$S(oref.IsEncrypted(Key,index):"Yes",1:"No")%></font></td></tr>>
				Set Value=oref.NextIndex(Key,.index)
			}
			
			Set Key = oref.Next(Key)
		}
	}
	
	&html<</table><br>>
	QUIT
}

/// Display a set of name/value pairs such as CGI variables or cookies.
ClassMethod dumpSet(oref As %String, Name As %String, Suffix As %String)
{
	New Key,Value,Row
	&html<<hr><br><p><b>#(Name)#</b></p>
<table cellpadding="5" border="1" width="100%">
<tr><th align="left" width="20%"><font face="Verdana, Arial, Helvetica, sans-serif"><b>Name</b></font></th>
<th align="left"><font face="Verdana, Arial, Helvetica, sans-serif"><b>Value</b></font></th></tr>>
	Set Key=$method(oref,"Next"_Suffix,""),Row=0
	If Key="" {
		&html<<tr bgcolor="#DDDDDD"><td><font face="Verdana, Arial, Helvetica, sans-serif"><i>Empty</i></font></td></tr>>
	} Else {
		Set Key=""
		For {
			Set Key=$method(oref,"Next"_Suffix,Key) Quit:Key=""
			Set Value=$method(oref,"Get"_Suffix,Key)
			Set Row=Row+1
			&html<<tr bgcolor="#($S(Row#2:"#DDDDDD",1:"#FFFFFF"))#"><td><font face="Verdana, Arial, Helvetica, sans-serif">#(..DecodeData(Key))#</font></td>
<td><font face="Verdana, Arial, Helvetica, sans-serif">#(..DecodeData(Value))#</font></td></tr>>
		}
	}
	&html<</table><br>>
	QUIT
}

/// Display the content of a multidimensional array.
ClassMethod dumpMultidimentional(Key As %String, Name As %String)
{
	New ref,Row
	Set ref=Key,Row=0
	&html<<hr><br><p><b>#(Name)#</b></p>
<table cellpadding="5" border="1" width="100%">
<tr><th align="left" width="20%"><font face="Verdana, Arial, Helvetica, sans-serif"><b>Name</b></font></th>
<th align="left"><font face="Verdana, Arial, Helvetica, sans-serif"><b>Value</b></font></th></tr>>
	If $Data(@ref)=0 {
		&html<<tr bgcolor="#DDDDDD"><td><font face="Verdana, Arial, Helvetica, sans-serif"><i>Empty</i></font></td></tr>>
	} ElseIf $Data(@ref)#10 {
		&html<<tr bgcolor="#DDDDDD"><td><font face="Verdana, Arial, Helvetica, sans-serif">#(..DecodeData(ref))#</font></td>
<td><font face="Verdana, Arial, Helvetica, sans-serif">#(..DecodeData(@ref))#</font></td></tr>>
		Set Row=1
	}
	Set ref=$Query(@ref)
	While ref'="" {
		Set Row=Row+1
		&html<<tr bgcolor="#($S(Row#2:"#DDDDDD",1:"#FFFFFF"))#"><td><font face="Verdana, Arial, Helvetica, sans-serif">#(..DecodeData(Key_"("_$Piece(ref,"(",3,*)))#</font></td>
<td><font face="Verdana, Arial, Helvetica, sans-serif">#(..DecodeData(@ref))#</font></td></tr>>
		Set ref=$Query(@ref)
	}
	&html<</table><br>>
	Quit
}

/// Display streams from request object.
ClassMethod dumpStreams(oref As %String, title As %String)
{
	New Key,Value,Row,Stream
	&html<<hr><br><p><b>#(title)#</b></p>
<table cellpadding="5" border="1" width="100%">
<tr><th align="left" width="20%"><b>Name</b></th><th align=left><font face="Verdana, Arial, Helvetica, sans-serif"><b>Size</b></font></th>
<th align="left"><font face="Verdana, Arial, Helvetica, sans-serif"><b>ContentType</b></font></th>
<th align="left"><font face="Verdana, Arial, Helvetica, sans-serif"><b>Section</b></font></th>
<th align="left"><font face="Verdana, Arial, Helvetica, sans-serif"><b>Class</b></font></th></tr>>
	Set Key=$method(oref,"NextMimeData",""),Row=0
	If Key="" &html<<tr bgcolor="#DDDDDD"><td><font face="Verdana, Arial, Helvetica, sans-serif"><i>Empty</i></font></td></tr>>
	Else  Set Key="" For  Set Key=$method(oref,"NextMimeData",Key) Quit:Key=""  Do
	. Set Stream=$method(oref,"GetMimeData",Key)
	. Set Row=Row+1
	. &html<<tr bgcolor="#($S(Row#2:"#DDDDDD",1:"#FFFFFF"))#"><td><font face="Verdana, Arial, Helvetica, sans-serif">#(..DecodeData(Key))#</font></td>
<td><font face="Verdana, Arial, Helvetica, sans-serif">#(..DecodeData(Stream.Size))#</font></td><td>#(..DecodeData(Stream.ContentType))#</td>
<td><font face="Verdana, Arial, Helvetica, sans-serif">#(..DecodeData(Stream.MimeSection))#</font></td>
<td><font face="Verdana, Arial, Helvetica, sans-serif">#(..DecodeData($classname(Stream)))#</font></td></tr>>
	&html<</table><br>>
	QUIT
}

/// Display <var>data</var> in human printable form.
ClassMethod DecodeData(data As %String) As %String [ Internal ]
{
	#; Special handling for streams
	If $isobject(data)=1,data.%IsA("%Stream.Object") {
		Set size=data.Size,first=data.Read(255)
		Set return=##class(%Studio.Global).format(first,.output)
		Set output=data_" Size="_size_" Inital="_output
	} Else {
		Set return=##class(%Studio.Global).format(data,.output)
	}
	Quit ..EscapeHTML(output)
}

}
