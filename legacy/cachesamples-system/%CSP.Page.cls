/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

IncludeGenerator %cspBuild

/// The <CLASS>%CSP.Page</CLASS> object serves as an event handler for CSP requests.  All .csp
/// pages by default derive from %CSP.Page, although you can override this using the &lt;CSP:CLASS&gt;
/// tag.  CSP Servlets can be created by deriving a class from %CSP.Page, see <class>%CSP.StreamServer</class>
/// as an example.
Class %CSP.Page Extends %Library.Base [ Abstract, System = 3 ]
{

/// Controls how the query parameters for this page are passed, it can 
/// be set to one of the following:<br>
/// <br><ul>
/// <li><b>ENCODED=0</b> - Query parameters are not encrypted</li>
/// <li><b>ENCODED=1</b> - Query parameters are encrypted and passed within CSPToken</li>
/// <li><b>ENCODED=2</b> - Same as '1' except any unencrypted parameters
/// are removed from the %request object before calling the <method>Page</method>
/// method. This ensures that only encrypted parameter are available in the
/// <class>%CSP.Request</class> object.</li>
/// </ul>
Parameter ENCODED = 0;

/// Controls the access to the page, it can be set to one of the following:<br>
/// <br><ul>
/// <li><b>PRIVATE=0</b> - Page can be linked to/bookmarked</li>
/// <li><b>PRIVATE=1</b> - Can only be referenced from another CSP page</li>
/// </ul>
/// The user needs initially to enter the site through a PUBLIC page.
Parameter PRIVATE = 0;

/// If this page was compiled from a .csp file, then this parameter contains the
/// filename used for compilation.
Parameter CSPFILE;

/// This parameter is used to make sure that if multiple
/// CSP applications are mapped to the same namespace that the CSP engine can correctly
/// identify which class corresponds with which URL. If 'LockCSPName' is true (the default, defined
/// in the CSP application) then you can only access this page if the url exactly matches
/// this 'CSPURL'. You can set this parameter to "" if you wish to disable this check for
/// this class. This check is applied for all CSP urls (cls/csp/zen).<br>
/// If this page was compiled from a .csp file, then this parameter is automatically set to contain the
/// url of this file used for compilation.
Parameter CSPURL;

/// Used to keep track of include files this page uses for dependency checking if this
/// page is still up to date. Only relevant for .csp files and not for class based pages.
Parameter CSPINCLUDES [ Internal ];

/// Specifies the default content type for the page.  This can be overriden using the
/// &lt;CSP:CONTENT TYPE=&gt; tag, or by setting the <b>%response</b>.ContentType property
/// in the <method>OnPreHTTP</method> method.  The default value if this parameter is
/// not set is text/html.
Parameter CONTENTTYPE;

/// Specifies the default character set for the page.  This can be overriden using the
/// &lt;CSP:CONTENT CHARSET=&gt; tag, or by setting the <b>%response</b>.CharSet property
/// in the <method>OnPreHTTP</method> method.  If this parameter is not specified, then
/// for the default charset is utf-8.
Parameter CHARSET;

/// Specifies if we wish to turn off charset conversion for this page. Normally CSP uses
/// the tables built into InterSystems IRIS to convert between different charset's, however if you
/// do not have a charset available you may wish to turn this off to avoid getting the
/// error page saying that this charset is not installed. Then the data will be output
/// and read in using RAW mode. This can be overridden using the &lt;CSP:CONTENT NOCHARSETCONVERT=1&gt;
/// tag, or by setting the <b>%response</b>.NoCharSetConvert property in the
/// <method>OnPreHTTP</method> method.
Parameter NOCHARSETCONVERT;

/// Specifies if input %request.Content or %request.MimeData values are converted from their
/// original character set on input. By default (0) we do not modify these and receive them
/// as a binary stream which may need to be converted manually later. If 1 then if there
/// is a 'charset' value in the request Content-Type or mime section we will convert from this
/// charset when the input data is text based. For either json or xml data with no charset
/// this will convert from utf-8 or honor the BOM if one is present.
Parameter CONVERTINPUTSTREAM = 0;

/// Specify a custom error page to call if there are any problems with generating this page.
/// If this is not specified it will use the default error page specified for this CSP
/// application, and if this is not specified it will use the system default error page.
/// For example this could be set to '/csp/samples/error.csp' to display the sample error
/// page.
Parameter ERRORPAGE;

/// Specified the default value for the %response.Expires.<br>
/// It can be set to one of the following values:<br>
/// <ul>
/// <li><b>-1</b>: Expire immediately, this is the default for a CSP page</li>
/// <li><b>0</b>: Expire immediately, this also sets the 'no-store' option so using the back button will request a new page</li>
/// <li><b>""</b>: Never expire (no HTTP Expires header is sent)</li>
/// <li><b>nnnnn</b>: Number of seconds from now when the object should expire</li>
/// <li><b>Thu, 29 Oct 1998 17:04:19 GMT</b>: Absolute time at which the object should expire</li>
/// <li><b>ddddd,sssss</b>: Absolute time the object should expire in $ZTimeStamp format. Note
/// that this must be specified in the GMT timezone</li>
/// </ul>
/// Note that setting this header also effects the 'Cache-Control' and 'Pragma' headers. If the page is set
/// to expire immediately then it will send a 'Cache-Control: no-cache' and 'Pragma: no-cache' to
/// prevent any caches from storing the page. If the page is set to never expires then it will not send
/// any 'Cache-Control' or 'Pragma' headers. If you set an expires date then it will not modify the
/// 'Cache-Control' or 'Pragma' headers so if they are set they will be sent as specified and if you did
/// not set them then nothing will be sent for these headers.
Parameter EXPIRES = -1;

/// Used by the timing to decide how many slots a day should be divided up into. The default is to record
/// the timings over half an hour (48 slots per day). If you need more detail you can modify this value in
/// the superclass.
Parameter TIMINGSLOTS = 48;

/// If this parameter is true then we automatically record timing statistics of how long it takes to
/// produce this page. It is off by default.
Parameter PAGETIMING = 0;

/// The default domain for csp:text, span and div tags.  This parameter is
/// used to specify the subset of localized messages to be used on this page.
Parameter DOMAIN;

/// The CSPXHTML parameter is set to 1, if the DOCTYPE indicates that this
/// is an XHTML page.
Parameter CSPXHTML;

/// The CSPSTRICT parameter is set to 1, if the DOCTYPE indicates that this
/// is a strict or frameset XHTML or HTML 4 page.
Parameter CSPSTRICT;

/// This is a comma-delimited list of system Resources and associated 
/// permissions. A user must hold the specified permissions on all
/// of the specified resources in order to view this page.<br/>
/// The format of each item in the list should be as follows:<br/>
/// Resource[:Permission] <br/>
/// Permission is optional, and defaults to USE if not supplied. If it
/// is supplied, it should be one of USE, READ or WRITE.
/// You can also specify
/// or grouping using the '|' character, so 'R1,R2|R3,R3|R4' means you must have
/// resource R1 and one of R2 or R3 and one of R3 or R4. So if you have R1,R3 it will
/// pass, if you have R1,R4 it will not as it does not meet the R2|R3 condition. So the
/// '|' or condition takes precedence over the ',' and condition.
Parameter SECURITYRESOURCE As STRING;

/// This parameter controls the CSP session support. By default CSP will use a persistent session
/// which holds a license until the session is ended or times out. If you override this then this
/// CSP page will use a transient session which is never persisted.
Parameter UseSession As BOOLEAN = 1;

/// Returns 1 if this page is in fact a private page (see <parameter>PRIVATE</parameter>).
ClassMethod IsPrivate() As %Boolean [ ServerOnly = 1 ]
{
	Quit ..#PRIVATE
}

/// Process a request to serve a CSPPage. This method is invoked by the 
/// <i>CSP Server</i>. In turn, this method invokes:
/// <p><ul>
/// <li><b>OnPreHTTP()</b></li>
/// <li><b>OnPage()</b></li>
/// <li><b>OnPostHTTP()</b></li>
/// </ul></p>
/// Note that <METHOD>OnPostHTTP()</METHOD> always gets run, even if there was an error.<br>
/// <var>skipheader</var> will skip the running of the OnPreHTTP() method.
ClassMethod Page(skipheader As %Boolean = 1) As %Status [ CodeMode = generator, GenerateAfter = (OnPreHTTP, OnPostHTTP, OnErrorSetup), ServerOnly = 1 ]
{
	Set %code=0,contenttype="",charset="",nocharsetconvert=""
	If $get(%parameter("PAGETIMING")) $$$GENERATE("	Do ..StartTimer(""Page"")")
	$$$GENERATE("	New %CSPsc Set %CSPsc=$$$OK")
	$$$GENERATE("	Set dopage=(%request.Method'=""HEAD"")")
	If $get(%parameter("CONTENTTYPE"))'="" Set contenttype=%parameter("CONTENTTYPE") $$$GENERATE("	Set %response.ContentType="""_contenttype_"""")
	If $get(%parameter("CHARSET"))'="" {
		Set charset=%parameter("CHARSET")
		If $$MapCharset^%SYS.NLS(charset)="" Quit $$$ERROR($$$CSPInvalidCharacterSet,charset)
		$$$GENERATE("	Set %response.CharSet="""_charset_"""")
	}
	If $get(%parameter("DOMAIN"))'="" $$$GENERATE("	Set %response.Domain="""_%parameter("DOMAIN")_"""")
	If $get(%parameter("EXPIRES"))'=-1 $$$GENERATE("	Set %response.Expires="""_%parameter("EXPIRES")_"""")
	If $get(%parameter("NOCHARSETCONVERT"))'="" Set nocharsetconvert=%parameter("NOCHARSETCONVERT") $$$GENERATE("	Set %response.NoCharSetConvert="""_nocharsetconvert_"""")
	If %classname="%CSP.StreamServer"||($$IsA^%occLibrary(%classname,"%CSP.StreamServer")) {
		$$$GENERATE("	Set %response.Language=""cs""")
	} Else {
		$$$GENERATE("	If %response.Language="""" Do %response.MatchLanguage()")
	}
	If contenttype=""||($piece(contenttype,"/")="text")||(contenttype="application/x-csp-hyperevent")||(charset'="") {
		#; Optimize for utf-8 as it is so common
		Set table=$select(nocharsetconvert:"RAW",charset="":$$FindDefaultCharset^%SYS.cspServer2(),$zconvert(charset,"l")="utf-8":"UTF8",1:$$MapCharset^%SYS.NLS(charset))
		If table="" Set table="UTF8"
		If table'="RAW" $$$GENERATE("	If 'skipheader $$$SETIO("""_table_""")")
	} Else {
		$$$GENERATE("	If 'skipheader $$$SETIO(""UTF8"")")
	}
	$$$GENERATE("	Try {")
	If $$$comMemberKeyGet(%class,$$$cCLASSmethod,"OnErrorSetup",$$$cMETHrunnable) $$$GENERATE("		If ..OnErrorSetup(.skipheader)=0 Set dopage=0")
	If $$$comMemberKeyGet(%class,$$$cCLASSmethod,"OnPreHTTP",$$$cMETHrunnable) $$$GENERATE("		If ..OnPreHTTP()=0 Set dopage=0")
	If $$$comMemberKeyGet(%class,$$$cCLASSmethod,"OnHTTPHeader",$$$cMETHrunnable) {
		$$$GENERATE("		If 'skipheader Set %CSPsc=..OnHTTPHeader(.dopage) Set:$$$ISERR(%CSPsc) dopage=0")
	} Else {
		$$$GENERATE("		If 'skipheader Set %CSPsc=%response.WriteHTTPHeader(.dopage) Set:$$$ISERR(%CSPsc) dopage=0")
	}
	$$$GENERATE("		If $get(dopage) Set %CSPsc=..OnPage()")
	$$$GENERATE("	} Catch exception {")
	$$$GENERATE("		If $ZError'[""<ZTHRO""||($get(%CSPsc)="""")||(+%CSPsc) Set %CSPsc=exception.AsStatus()")
	If $$$comMemberKeyGet(%class,$$$cCLASSmethod,"OnPageError",$$$cMETHrunnable) $$$GENERATE("		Do ..OnPageError(.%CSPsc)")
	$$$GENERATE("	}")
	If $$$comMemberKeyGet(%class,$$$cCLASSmethod,"OnPostHTTP",$$$cMETHrunnable) $$$GENERATE("	Do ..OnPostHTTP()")
	If $get(%parameter("PAGETIMING")) $$$GENERATE("	Do ..StopTimer(""Page"")")
	$$$GENERATE("	Quit %CSPsc")
	QUIT $$$OK
}

/// Display a <class>%Status</class> error code to the CSP Page.
ClassMethod ShowError(sc As %Status) [ ServerOnly = 1 ]
{
	Do ShowError^%SYS.cspServer2(sc)
}

/// Passed a <class>%Status</class> code this goes to the error page passing this status code
ClassMethod ThrowError(sc As %Status) [ ServerOnly = 1 ]
{
	Set %CSPsc=sc
	ZTrap "THROW"
}

/// Event handler for <b>PreHTTP</b> event: this is invoked before
/// the HTTP headers for a CSP page have been sent.  All changes to the
/// <class>%CSP.Response</class> class, such as adding cookies, HTTP headers,
/// setting the content type etc. must be made from within the OnPreHTTP() method.
/// Also changes to the state of the CSP application such as changing
/// %session.EndSession or %session.AppTimeout must be made within the OnPreHTTP() method.
/// It is prefered that changes to %session.Preserve are also made in the OnPreHTTP() method
/// as this is more efficient, although it is supported in any section of the page.
/// Return <b>0</b> to prevent <method>OnPage</method> from being called.
ClassMethod OnPreHTTP() As %Boolean [ Abstract, ServerOnly = 1 ]
{
}

/// Event handler which is invoked before a hyperevent method is called on this page.
/// This gives you a chance to modify the behavior of every hyperevent call
/// within this page.
/// Return an error code to prevent the hyperevent from being called.
ClassMethod OnPreHyperEvent(class As %String, method As %String) As %Status [ CodeMode = expression, ServerOnly = 1 ]
{
$$$OK
}

/// Event handler which is invoked after a hyperevent method is called on this page.
ClassMethod OnPostHyperEvent(class As %String, method As %String) As %Status [ CodeMode = expression, ServerOnly = 1 ]
{
$$$OK
}

/// Event handler for <b>PAGE</b> event: this is invoked in order to  
/// send HTTP headers. The default action is to invoke the WriteHTTPHeader()
/// of the <class>%CSP.Response</class> which generates HTTP 1.0 standard
/// headers. Set <var>OutputBody</var> to 0 to prevent prevent <method>OnPage</method>
/// from being called, leave it unchanged otherwise. Returns a <class>%Status</class> code.
ClassMethod OnHTTPHeader(ByRef OutputBody As %Boolean) As %Status [ Abstract, ServerOnly = 1 ]
{
}

/// Event handler for <b>PAGE</b> event: this is invoked in order to  
/// generate the content of a csp page.
ClassMethod OnPage() As %Status [ ServerOnly = 1 ]
{
	Quit $$$OK
}

/// Event handler for <b>POSTPAGE</b> event: this is invoked after the data
/// for the CSP page has been sent to the browser from the the InterSystems IRIS server.
ClassMethod OnPostHTTP() [ Abstract, ServerOnly = 1 ]
{
}

/// Event handler for any error that occurs on the page. If an error occurs and this method
/// is defined it calls this method passing it the error code by reference. You may change
/// the error code if wished, if you set it to $$$OK then it will cancel the error and the
/// CSP error page will not be displayed.
ClassMethod OnPageError(ByRef sc As %Status) [ Abstract, ServerOnly = 1 ]
{
}

/// Tranforms the link specified by <VAR>link</VAR> into a URL and returns it as a string.
/// <p>The URL may be encrypted.</p>
/// <p>The array, <VAR>query</VAR>, contains an optional set of name-value pairs 
/// which are added to the URL. For example 'Set query("name")="data"'</p>
/// <p>If the optional argument <var>addQ</var> is true, then a ? or &amp;,
/// as appropriate, is added to end of the URL</p>
ClassMethod Link(link As %String, ByRef query As %String, addQ As %Boolean = 0) As %String [ ServerOnly = 1 ]
{
	Quit $$cspLink^%SYS.cspServer(link,.query,addQ)
}

/// Encrypts the input string using the %session.Key value that is unique to this
/// user session. The output string is a string that can be included in HTML and
/// in URLs as it does not contain any characters that need to be escaped in these
/// environments. It can be decrypted with the <method>Decrypt</method>.<p>
/// Note that the <var>data</var> must not contain any unicode characters as the encryption
/// function just takes a byte stream. If you wish to encrypt unicode data then the simplest
/// way is to form a $listbuild of the string first to convert it into a byte stream.<p>
/// This function should only be used to encrypt server side data, do not make this function
/// available from a client or allow data passed from a client say as a url parameter to be encrypted
/// and returned to the client. If you do this will break the CSP security model as a client will be
/// able to ask the server to encrypt any value they choose and so the server can not rely on the
/// decrypted values as a client will be able to create and pass any encrypted value they want.
/// Also you only want to encrypt data which is valid for this entire session, so be aware that data
/// that page a.csp encrypted could be copied by a client and inserted into a request for page b.csp.
ClassMethod Encrypt(data As %Binary) As %String [ CodeMode = expression, ServerOnly = 1 ]
{
$$$cspEncode(%session.Key,data)
}

ClassMethod EncryptBroker(data As %Binary) As %String [ CodeMode = expression, Internal, ServerOnly = 1 ]
{
$$$cspEncodeBroker(%session.Key,data)
}

/// Decrypts the input string using the %session.Key value that is unique to
/// this user session. The input string is the string provided by the
/// <method>Encrypt</method> method, the output is the decoded string.
ClassMethod Decrypt(data As %String) As %Binary [ ServerOnly = 1 ]
{
	$$$cspDecodeCheck(var,%session.Key,data)
	Quit var
}

/// This method converts the <var>in</var> input URL string into Escaped URL string.
/// Note that '/' is not escaped which is consistent with rfc3986. The conversion first encodes the string
/// using the current devices charset and then url encodes the result. If you pass in <var>charset</var>
/// then we will use this rather than the current devices charset for the encoding.
ClassMethod EscapeURL(in As %String, charset As %String) As %String [ CodeMode = expression, ServerOnly = 1 ]
{
$zconvert($zconvert(in,"O",$select($data(charset)#10=1:charset,1:$replace($$$GETIO,"JSML","UTF8"))),"O","URL")
}

/// This method converts the <var>in</var> Escaped URL string back to its original form.
/// The conversion first unescapes the URL then decodes the string
/// using the current devices charset. If you pass in <var>charset</var>
/// then we will use this rather than the current devices charset for the decoding.
ClassMethod UnescapeURL(in As %String, charset As %String) As %String [ CodeMode = expression, ServerOnly = 1 ]
{
$zconvert($zconvert(in,"I","URL"),"I",$select($data(charset)#10=1:charset,1:$replace($$$GETIO,"JSML","UTF8")))
}

/// This method converts input HTML text into Escaped HTML text.
ClassMethod EscapeHTML(in) As %String [ CodeMode = expression, ServerOnly = 1 ]
{
$zconvert(in,"O","HTML")
}

/// This method converts Escaped HTML text into normal HTML text
ClassMethod UnescapeHTML(in) As %String [ CodeMode = expression, ServerOnly = 1 ]
{
$zconvert(in,"I","HTML")
}

/// This method converts input string into quoted JavaScript literal
ClassMethod QuoteJS(in) As %String [ CodeMode = expression, ServerOnly = 1 ]
{
"'"_$zconvert(in,"O","JS")_"'"
}

/// This method will rewrite a URL to use #url()# if needed
ClassMethod RewriteURL(url As %String) As %String [ ServerOnly = 1 ]
{
	If url'?1"#url("1.e1")#".e {
		Set ext=$piece(url,"?")
		If (ext["#(")&&(ext[")#")&&(ext'["..Link(") {
			Set url="#url("_url_")#"
		} Else {
			Set ext=$$$NormalizeFilename($piece($piece(url,"#"),"?"))
			If $case($piece(ext,".",*),"csp":1,"cls":1,"zen":1,:0) {
				Set url="#url("_url_")#"
			}
		}
	}
	Quit url
}

/// Include another csp page or file in the output at this point. If the url ends in either
/// 'csp' or 'cls' then it will call the csp or cls class to generate output skipping the
/// output of the HTML headers. If the url is a file then it uses the stream server to output
/// this file. This url can be a relative path in which case it will be resolved based on the
/// current page url first. This is called by the &lt;csp:include Page="page.csp"&gt; tag.<p>
/// You can pass additional parameters to the included page by adding them to the url to
/// call. These parameters will only exist for the included page and the %request object is
/// restored when it returns to the calling page. For example:<p>
/// &lt;csp:include Page="page.csp?PARAM=VALUE"&gt;
ClassMethod Include(url As %String) [ ServerOnly = 1 ]
{
	Set %CSPsc=$$cspInclude^%SYS.cspServer(url)
	If $$$ISERR(%CSPsc) Set %request.Data("Error:IncludePage",1)=url ZTrap "THROW"
	Kill %CSPsc
}

/// This method returns the string that needs to be written to the current
/// device during generation of the &lt;head&gt; section in order
/// to use HyperEvents.  See <method>HyperEventCall</method> for details.
/// This is not needed if you are using #server, #vbserver or #call calls from
/// a .csp page as this is automatically inserted, it is only required when 
/// generating the class or the HyperEvent calls directly.
/// The <var>iframeonly</var> argument is now ignored since #call and #server now both use XMLHttpRequest.
/// However, the iframeonly argument is kept for compatibility.
/// Passing the argument strict=1 will create strict HTML 4 format of script tag.
ClassMethod HyperEventHead(iframeOnly As %Boolean, strict As %Boolean = 0, optionalBroker As %Boolean) As %String [ CodeMode = expression, ServerOnly = 1 ]
{
$select(strict:$$$cspStrictBrokerInsertHttpJS,1:$$$cspBrokerInsertHttpJS)_$select($get(optionalBroker,$get(^%SYS("CSP","OptionalBrokerJS"),0)):"",1:$select(strict:$$$cspStrictBrokerInsertJS,1:$$$cspBrokerInsertJS))
}

/// This method is deprecated since Java applet based hyperevents are no longer supported.
ClassMethod HyperEventBody() As %String [ CodeMode = expression, Deprecated, Internal, ServerOnly = 1 ]
{
""
}

/// This method is deprecated since iframe based hyperevents are no longer supported.
ClassMethod HyperEventFrame(strict As %Boolean) As %String [ CodeMode = expression, Deprecated, Internal, ServerOnly = 1 ]
{
""
}

/// This method returns the string that needs to be written to the current
/// device in order to insert a HyperEvent into a CSP page that is defined via
/// a class. This method is the hand written class equivalent of using #call(...)#,
/// #server(...)# or #vbserver(...)# in a CSP page.<p></p>
/// <p>The <var>methodName</var> argument defines the method to call in the same
/// format as #server: either ..method or package.class.method.</p>
/// <p>The <var>args</var> argument defines the runtime JavaScript arguments
/// to be passed to the ObjectScript method as a comma separated string.</p>
/// <p>The <var>type</var> argument is 0 if you wish to use a #server(...)# style HyperEvent
/// (this is the default), 1 if you wish to use a #call(...) style HyperEvent. Note that browsers
/// are deprecating the synchronous #server(...)# style XMLHttpRequest so application should
/// transition to using type=1. If the argument is 0 then it will use double quotes for the JavaScript which is
/// the behaviour of #vbserver in a csp page, this will work correctly in both JavaScript
/// and VBScript but you need to be aware that it will quote its parameter with ".</p><p></p>
/// <p>In order to use this method, <method>HyperEventHead</method> must
/// be used in the &lt;head&gt; section.</p>
/// <p></p><p> An example of an OnPage method for your page using a #call(...)# style HyperEvent:</p>
/// <example>
/// Write "<html>",!
/// Write "<head>",!
/// Write ..HyperEventHead(),!
/// Write "</head>",!
/// Write "<body>",!
/// Write "My New CSP Page!",!
/// Write "<form name=""f"">",!
/// Write "<input type=""text"" name=""f1"" value=""fieldabc"">",!
/// Write "<input type=""text"" name=""f2"" value=""fielddef"">",!
/// Write "<input type=""button"" value=""Go"" onclick='"
/// Write ..HyperEventCall("..MyMethod","self.document.f.f1.value,self.document.f.f2.value",1)
/// Write ";'>",!
/// Write "</form>",!
/// Write "</body>",!
/// Write "</html>",!
/// Quit $$$OK
/// </example>
ClassMethod HyperEventCall(methodName As %String, args As %String, type As %Integer = 0, mobile As %Boolean = 0) As %String [ ServerOnly = 1 ]
{
	Set output=$Select(type=0:"cspHttpServerMethod",1:"cspCallHttpServerMethod")
	If mobile {
		Set output=output_"Mobile"_"("""_$select($extract(methodName,1,2)="..":$classname()_$extract(methodName,2,*),1:methodName_":"_$classname()_"")
	} Else {
		Set output=output_"("""_$$$cspEncodeBroker(%session.Key,$listbuild($select($extract(methodName,1,2)="..":$classname()_$extract(methodName,2,*),1:methodName_":"_$classname()_"")))
	}
	Quit output_$select(%session.UseSessionCookie'=2:"&amp;CSPCHD="_%session.CSPSessionCookie,1:"")_""""_$select($get(args)'="":","_args,1:"")_")"
}

/// Return the string containing the hidden form tags.
/// You pass it the <parameter>url</parameter> URL of the target page that
/// this form is submitted to (the action=xxx attribute).
/// <p>The array, <parameter>query</parameter>, contains an optional set of name-value pairs 
/// which are also output as hidden input fields. This is normally called automatically directly after
/// the &lt;FORM&gt; tag to insert any hidden input tags that are required. However if you generate a form
/// programatically then you may need to call this function just after you output the &lt;FORM&gt; tag.</p>
ClassMethod InsertHiddenFields(url As %String, ByRef query As %String) As %String [ CodeMode = expression, ServerOnly = 1 ]
{
$$cspHiddenForm^%SYS.cspServer(.url,.query,..#CSPXHTML)
}

/// Inserts a '&lt;input type="hidden" name="Name" value="Value"&gt;' tag into the current document.
/// If the target url you are submitting to (<parameter>url</parameter>) is encoded then this
/// will encrypt the data in this hidden link. In this way it is similar to the <method>Link</method>.
/// The <parameter>extra</parameter> are any extra attributes to add to the tag.<p>
/// For example:
/// <example language=HTML>
/// <form action="target.csp">
/// #(..InsertHiddenField("target.csp","Name","Value"))#
/// <input type=submit name=Submit>
/// </form>
/// </example>
ClassMethod InsertHiddenField(url As %String, name As %String, value As %String, extra As %String = "") As %String [ ServerOnly = 1 ]
{
	Do ..ConvertParameter(url,.name,.value)
	Quit "<input type=""hidden"" name="""_$zconvert(name,"O","HTML")_""" value="""_$zconvert(value,"O","HTML")_""" "_$zstrip(extra,"<>W")_"/>"
}

/// You pass this the <parameter>url</parameter> of the page you are going to and a
/// <parameter>name</parameter> and <parameter>value</parameter> parameter and
/// it will return the name and value encrypted if the target page is encoded.
ClassMethod ConvertParameter(url As %String, ByRef name As %String, ByRef value As %String) As %Status [ ServerOnly = 1 ]
{
	Set url=$Piece(url,"?")
	Set className=$$GetCSPClassName^%SYS.cspServer(url,%request.URL) Quit:className="" $$$OK
	If $$$comMemberKeyGet(className,$$$cCLASSparameter,"ENCODED",$$$cPARAMdefault)'=0 Set value=$$$cspEncode(%session.Key,$listbuild($listbuild(name,value))),name="CSPToken"
	Quit $$$OK
}

/// Used to get performance information on your CSP pages. This is called to start the timing
/// of a block of code. The <var>name</var> specifies the type of component we are timing,
/// for example we automatically call this with 'Page' at the start and end of the rendering
/// of the CSP page. The idea is that you can call this at the start and end of any block
/// of code to log information on how long this is taking.<p>
/// This is a default implementation of what sort of information to log, however you can
/// subclass this and <method>StopTimer</method> to enhance the information that is logged.
ClassMethod StartTimer(name As %String) [ ServerOnly = 1 ]
{
	Set %response.Timers(name)=$zhorolog,%response.Timers(name,"globals")=$$$GlobalRefs,%response.Timers(name,"lines")=$zu(67,8,$job)
}

/// Used to time performance information on your CSP pages. This is called to stop the timing
/// of a block of code. The <var>name</var> specifies the type of component to time. See
/// <method>StartTimer</method> for more information on this.
ClassMethod StopTimer(name As %String) [ ServerOnly = 1 ]
{
	If '$data(%response.Timers(name)) Quit
	Set time=$zhorolog-%response.Timers(name),day=$zdate($horolog,3),slot=$piece($horolog,",",2)*..#TIMINGSLOTS\86400,url=$select($get(%request.Data("CSPInclude",1))'="":%request.Data("CSPInclude",1),1:%request.URL)
	Set globals=$$$GlobalRefs-%response.Timers(name,"globals"),lines=$zu(67,8,$job)-%response.Timers(name,"lines")-4
	If $increment(^|"^^"_$zutil(12)|ISCcspPerformance(name,url,day,slot,"hit")),$increment(^("time"),time),$increment(^("globals"),globals),$increment(^("lines"),lines)
	#; As we are not locking the following two lines have a potential hole, however
	#; as the point is to get some general timing statistics rather than exact measurements this is acceptable.
	If $get(^("min"),99999999)>time { Set ^("min")=time }
	If $get(^("max"),0)<time { Set ^("max")=time }
	Quit
}

}
