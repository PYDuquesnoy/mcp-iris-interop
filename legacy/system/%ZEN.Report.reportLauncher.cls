/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sySystem

/// 
Class %ZEN.Report.reportLauncher Extends %CSP.Page [ Abstract, Deprecated, System = 4 ]
{

Parameter REPORTCLASS As STRING;

Parameter HOST As STRING = "localhost";

Parameter PORT As STRING = 57772;

Parameter URL As STRING = "csp/samples";

ClassMethod OnPage() As %Status
{
 &html<
 <html>
 <head>
 </head>
 <body>
 <form name='everything'>
 <tr>
 >
 d ..GenerateInputTextAreas()

 w !,"</tr>"
 w !,"<br>"
 w !,"<input type='button' value='Generate Report' onclick=""generateReport('"_..#HOST_"','"_..#PORT_"','"_..#URL_"','"_..#REPORTCLASS_"')""></input>"
 &html< 
 </form>

 <script>
 function generateReport(host,port,url,clazz) {
	 var f = document.everything;
	 var cspurl = "http://"+host+":"+port+"/"+url+"/"+clazz+".cls";
	 var sep="?";
	 for (var i=0; i < f.elements.length; i++) {
		 var e = f.elements[i];
		 if (e.className = "param" && e.name != "") {
			cspurl = cspurl + sep + e.name+"="+e.value;
			sep = "&";
		
		 }
	 }
	 cspurl=cspurl.replace(" ","%20");
	 window.open(cspurl);
	 return false;
 }
 </script>
 </body>
 </html>
 >
 Quit $$$OK
}

ClassMethod GenerateInputTextAreas() As %Status [ CodeMode = objectgenerator, Internal ]
{
	If (%class.Abstract) {
		Do %code.WriteLine(" Quit $$$OK")
		Quit $$$OK
	}
	Set classname=""
	For n = 1:1:%compiledclass.Parameters.Count() {
		Set tParam = %compiledclass.Parameters.GetAt(n)
		if (tParam.Name="REPORTCLASS") Set classname=tParam.Default
	}
	If (classname="") {
		Do %code.WriteLine(" w ""Parameter REPORTCLASS is null"",!")
		Do %code.WriteLine(" quit $$$OK")
		Quit $$$OK
	}
	Set compiledclass=##class(%Dictionary.CompiledClass).%OpenId(classname)
	If (compiledclass="") {
		Do %code.WriteLine(" w !,"""_classname_" cannot be opened!""")
		Do %code.WriteLine(" quit $$$OK")
	}
	Do %code.WriteLine(" w !,""<label for='$MODE'>Enter Mode:</label><input type='text' name='$MODE' id='$MODE' class='param'></td><br/>""")
    #; find all properties with ZENURL parameter defined
	Do %code.WriteLine(" Set tSC = $$$OK")
	Set i=1
	For n = 1:1:compiledclass.Properties.Count() {
		Set tProp = compiledclass.Properties.GetAt(n)
		Set tParam = tProp.Parameters.GetAt("ZENURL")
		If (tParam'="") {
			
			Do %code.WriteLine(" w !,""<label for='"_tParam_"'>Enter "_tProp.Name_":</label><input type='text' name='"_tParam_"' id='"_tParam_"' class='param'></td><br/>""")
			Set i=$i(i)
		}
	}
	Do %code.WriteLine(" Quit tSC")
	Quit $$$OK
}

}
