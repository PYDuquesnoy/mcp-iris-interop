/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Parses a url into component parts
Class %Net.URLParser Extends %Library.RegisteredObject [ Not ProcedureBlock, System = 3 ]
{

/// WARNING: This method has been deprecated in favor of <METHOD>Decompose</METHOD>.
/// <P>
/// Parses an url into its constituent components.
/// <P>
/// The output parameter 'Components' will contain an array subscripted by the name of the component
/// part with the parsed value as the data. E.G. for a URL such as 
/// <P>
/// http://www.intersystems.com
/// <P>
/// the 
/// Components array will contain the scheme in this form:- Components("scheme")="http"
/// <BR>
/// URLs are described briefly below, please see RFC1738 for a full description
/// <P>
/// A URL contains the name of the scheme being used (&lt;scheme&gt;) followed by a colon and then a string 
/// (the &lt;scheme-specific-part&gt;) whose interpretation depends on the scheme.
/// <P>
/// Scheme names consist of a sequence of characters. The lower case letters "a"--"z", digits, and the 
/// characters plus ("+"), period ("."), and hyphen ("-") are allowed. For resiliency, programs interpreting 
/// URLs should treat upper case letters as equivalent to lower case in scheme names
/// (e.g., allow "HTTP" as well as "http").
/// <P>
/// While the syntax for the rest of the URL may vary depending on the particular scheme selected, URL schemes 
/// that involve the direct use of an IP-based protocol to a specified host on the Internet use a common syntax 
/// for the scheme-specific data:
/// <BR>
/// //&lt;user&gt;:&lt;password&gt;@&lt;host&gt;:&lt;port&gt;/&lt;url-path&gt;
/// <P>
/// Some or all of the parts "&lt;user&gt;:&lt;password&gt;@",
/// ":&lt;password&gt;",
/// ":&lt;port&gt;", and "/&lt;url-path&gt;" may be excluded.
/// <P>
/// The scheme specific data start with a double slash "//" to indicate that it complies with the common Internet 
/// scheme syntax. The different components obey the following rules: 
/// <UL>
/// <LI>user
/// <BR>
/// An optional user name. Some schemes (e.g., ftp) allow the specification of a user name.</LI>
/// <P>
/// <LI>password
/// <BR>
/// An optional password. If present, it follows the user name separated from it by a colon. 
/// The user name (and password), if present, are followed by a commercial at-sign "@". Within the user and password 
/// field, any ":", "@", or "/" must be encoded.
/// <P>
/// Note that an empty user name or password is different than no user name or password; there is no way to specify 
/// a password without specifying a user name. E.g., &lt;URL:ftp://@host.com/&gt; has an empty user name and no password,
/// &lt;URL:ftp://host.com/&gt; has no user name, while &lt;URL:ftp://foo:@host.com/&gt; has a user name of "foo" and an empty
/// password.</LI>
/// <P>
/// <LI>host
/// <BR>
/// The fully qualified domain name of a network host, or its IP address as a set of four decimal digit groups 
/// separated by ".". Fully qualified domain names take the form as described in Section 3.5 of RFC 1034 [13] and 
/// Section 2.1 of RFC 1123 [5]: a sequence of domain labels separated by ".", each domain label starting and ending with an alphanumerical character and possibly also containing "-" characters. The rightmost domain label will never start with a digit, though, which 
/// syntactically distinguishes all domain names from the IP addresses.</LI>
/// <P>
/// <LI>port
/// <BR>
/// The port number to connect to. Most schemes designate protocols that have a default port number. Another port number
/// may optionally be supplied, in decimal, separated from the host by a colon. If the port is omitted, the colon is as 
/// well.</LI>
/// <P>
/// <LI>path<BR>
/// The rest of the locator consists of data specific to the scheme, and is known as the "path". It supplies the 
/// details of how the specified resource can be accessed. Note that the "/" between the host (or port) and the path 
/// is NOT part of the path. 
/// The path syntax depends on the scheme being used, as does the manner in which it is interpreted.</LI>
/// </UL>
ClassMethod Parse(Url As %Library.String, ByRef Components As %Library.String) [ Deprecated, Final ]
{
#;
#; Parse Url returning Components according to RFC 1808 
#;
#; Pick out fragment
 If Url["#" {
 Set Components("fragment")=$Piece(Url,"#",2,$Length(Url,"#")),Url=$Piece(Url,"#")
 } else {
 Set Components("fragment")=""
 }
#;
#; Pick out scheme
 New c,i,p
 For i=1:1:$Length(Url) Set c=$Extract(Url,i) If (c'?1AN)!("+-."[c) Quit
 Set p=$Find($Extract(Url,1,i),":",2) 
 If p>2 {
 Set Components("scheme")=$Extract(Url,1,p-2)
 Set Url=$Extract(Url,p,$Length(Url))
 } else {
 Set Components("scheme")=""
 }
#;
#; Pick out the netloc
 If $Extract(Url,1,2)="//" {
 New tNetloc Set tNetloc=$Piece($Piece(Url,"//",2),"/")
 If tNetloc["?" Set tNetloc=$Piece(tNetloc,"?")
 Set Components("netloc")=tNetloc
 If tNetloc'="" {
 Set Url=$Piece(Url,tNetloc,2,$Length(Url,tNetloc))
 } else {
	Set Url=$Piece(Url,"///",2,$Length(Url,"///"))
 }
 New tLen Set tLen=$Length(tNetloc,":")
 If tLen=1 {
	 	Do ..ParseHost(tNetloc,.Components)
 } elseif tLen=2 {
	 	If $Piece(tNetloc,":",2)?1N.N {
		 	Set Components("port")=$Piece(tNetloc,":",2)
		 	Do ..ParseHost($Piece(tNetloc,":"),.Components)
	 	} else {
		 	Set Components("username")=$Piece(tNetloc,":")
		 	Do ..ParseHost($Piece(tNetloc,":",2),.Components)
	 	}
 } elseif tLen=3 {
	 	Set Components("username")=$Piece(tNetloc,":"),Components("port")=$Piece(tNetloc,":",3)
	 	Do ..ParseHost($Piece(tNetloc,":",2),.Components) 
 }
 } else {
 Set Components("netloc")=""
 }
#;
#; Pick out the query
 If Url["?" {
 Set Components("query")=$Piece(Url,"?",2,$Length(Url,"?"))
 Set Url=$Extract(Url,1,$Find(Url,"?")-2)
 } else {
 Set Components("query")=""
 }
#;
#; Pick out the params
 If Url[";" {
 Set Components("params")=$Piece(Url,";",2,$Length(Url,";"))
 Set Url=$Extract(Url,1,$Find(Url,";")-2)
 } else {
 Set Components("params")=""
 }
#;
#; Pick out the path
 Set Components("path")=Url
#;
#; All done
 Quit
}

/// Parses an URL into its constituent components. <P>
/// The input parameters 'Url' is the string to parse. Some or all of the parts "&lt;user&gt;:&lt;password&gt;@", ":&lt;password&gt;", ":&lt;port&gt;", and "/&lt;path&gt;" may be excluded. <P>
/// The output parameter 'Components' will contain an array subscripted by the name of the component part with the parsed value as the data. <BR>
/// <Example>do ##class(%Net.URLParser).Decompose("http://user:pass@www.intersystems.com:80/path/",.Components)</example>
/// Components("host")="www.intersystems.com"<br>
/// Components("netloc")="user:pass@www.intersystems.com:80"<br>
/// Components("password")="pass"<br>
/// Components("path")="/path/"<br>
/// Components("port")=80<br>
/// Components("scheme")="http"<br>
/// Components("username")="user"
/// <P>
/// URLs are described briefly below, please see RFC1738 for a full description
/// <UL><LI>A URL contains the name of the scheme being used (&lt;scheme&gt;) followed by a colon and then a string 
/// (the &lt;scheme-specific-part&gt;) whose interpretation depends on the scheme.</LI>
/// <LI>Scheme names consist of a sequence of characters. The lower case letters "a"--"z", digits, and the 
/// characters plus ("+"), period ("."), and hyphen ("-") are allowed. For resiliency, programs interpreting 
/// URLs should treat upper case letters as equivalent to lower case in scheme names
/// (e.g., allow "HTTP" as well as "http").</LI>
/// <LI>While the syntax for the rest of the URL may vary depending on the particular scheme selected, URL schemes 
/// that involve the direct use of an IP-based protocol to a specified host on the Internet use a common syntax 
/// for the scheme-specific data:
/// <BR>
/// //&lt;user&gt;:&lt;password&gt;@&lt;host&gt;:&lt;port&gt;/&lt;path&gt;</LI></UL>
/// <P>
/// The scheme specific data start with a double slash "//" to indicate that it complies with the common Internet 
/// scheme syntax. The different components obey the following rules: 
/// <UL>
/// <LI><b>user</b> - An optional user name. Some schemes (e.g., ftp) allow the specification of a user name.</LI>
/// <LI><b>password</b> - An optional password. If present, it follows the user name separated from it by a colon. 
/// The user name (and password), if present, are followed by a commercial at-sign "@". Within the user and password 
/// field, any ":", "@", or "/" must be encoded.<BR>
/// Note that an empty user name or password is different than no user name or password; there is no way to specify 
/// a password without specifying a user name. E.g., &lt;URL:ftp://@host.com/&gt; has an empty user name and no password,
/// &lt;URL:ftp://host.com/&gt; has no user name, while &lt;URL:ftp://foo:@host.com/&gt; has a user name of "foo" and an empty
/// password.</LI>
/// <LI><b>host</b> - The fully qualified domain name of a network host, or its IP address as a set of four decimal digit groups 
/// separated by ".". Fully qualified domain names take the form as described in Section 3.5 of RFC 1034 [13] and 
/// Section 2.1 of RFC 1123 [5]: a sequence of domain labels separated by ".", each domain label starting and ending with an alphanumerical character and possibly also containing "-" characters. The rightmost domain label will never start with a digit, though, which syntactically distinguishes all domain names from the IP addresses.</LI>
/// <LI><b>port</b> - The port number to connect to. Most schemes designate protocols that have a default port number. Another port number
/// may optionally be supplied, in decimal, separated from the host by a colon. If the port is omitted, the colon is as 
/// well.</LI>
/// <LI><b>path</b> - The rest of the locator consists of data specific to the scheme, and is known as the "path". It supplies the 
/// details of how the specified resource can be accessed. <BR>
/// The path syntax depends on the scheme being used, as does the manner in which it is interpreted.</LI>
/// <LI><b>netloc</b> - The portion of the URL containing the username, password, host, and port. This is provided for when user needs the URL without any parsing. This is normally the same as &lt;user&gt;:&lt;password&gt;@&lt;host&gt;:&lt;port&gt;, but not always.</LI>
/// </UL>
ClassMethod Decompose(Url As %Library.String, ByRef Components As %Library.String) [ Final, ProcedureBlock = 1 ]
{

	#; Check if Url contains a scheme. If yes, get it and remove it from Url.
	For i = 1:1:$LENGTH(Url) If ($EXTRACT(Url,i)'?1AN) Quit
	Set p = $FIND($EXTRACT(Url,1,i),":",2)
	If p > 2 {
		Set Components("scheme") = $ZCONVERT($EXTRACT(Url,1,p-2),"i","URL")
		Set Url = $EXTRACT(Url,p,$LENGTH(Url))
	}
	
	If $EXTRACT(Url,1,3) = "///" { //Check if first 3 chars are //. This is a file URL.
		Set Url = $EXTRACT(Url,3,*) //Remove the first 2 /'s that aren't part of the path.
	}
	ElseIf $EXTRACT(Url,1,2) = "//" { //Check if first 2 chars are //.
		Set netloc = $PIECE($PIECE(Url,"//",2),"/")
		Set Components("netloc") = netloc
		If netloc '= "" {
			Set Url = $PIECE(Url,netloc,2,$LENGTH(Url,netloc))
		}
		Else {
			Set Url = $PIECE(Url,"//",2,$LENGTH(Url,"//"))
		}
		Set tLen = $LENGTH(netloc,":") //# of : in netloc + 1
		If tLen = 1 { //0 :
			If netloc["@" { //There's a username before host.
				Set Components("username") = $ZCONVERT($PIECE(netloc,"@"),"i","URL")
				Set Components("host") = $PIECE(netloc,"@",2)
			}
			Else { //Just a host.
				Set Components("host") = netloc
			}
		}
		ElseIf tLen = 2 { //1 :
			If netloc["@" { //There are credentials.
				Set userpass = $PIECE(netloc,"@")
				Set hostport = $PIECE(netloc,"@",2)
				If $PIECE(userpass,":") '= userpass { //: before @
					Set Components("username") = $ZCONVERT($PIECE(userpass,":"),"i","URL")
					Set Components("password") = $ZCONVERT($PIECE(userpass,":",2),"i","URL")
					Set Components("host") = hostport
				}
				Else { //No : before @
					Set Components("username") = $ZCONVERT(userpass,"i","URL")
					#; Test for IPv6
					Set locopen = $FIND(hostport,"[")
					Set locclosed = $FIND(hostport,"]")
					If (locopen > 0) && (locclosed > 0) && (locopen < locclosed) { //Yes IPv6
						Set Components("host") = $EXTRACT(hostport,locopen,locclosed-2)
					}
					Else { //No IPv6
						Set Components("host") = $PIECE(hostport,":")
						Set Components("port") = $PIECE(hostport,":",2)
					}
				}
			}
			Else { //No credentials.
				#; Test for IPv6
				Set locopen = $FIND(netloc,"[")
				Set locclosed = $FIND(netloc,"]")
				If (locopen > 0) && (locclosed > 0) && (locopen < locclosed) { //Yes IPv6
					Set Components("host") = $EXTRACT(netloc,locopen,locclosed-2)
				}
				Else { //No IPv6
					Set Components("host") = $PIECE(netloc,":")
					Set Components("port") = $PIECE(netloc,":",2)
				}
			}
	 	}
	 	ElseIf tLen = 3 { //2 :
	 		If netloc["@" { //There are credentials.
				Set userpass = $PIECE(netloc,"@")
				Set hostport = $PIECE(netloc,"@",2)
				If $PIECE(userpass,":") '= userpass {
					Set Components("username") = $ZCONVERT($PIECE(userpass,":"),"i","URL")
					Set Components("password") = $ZCONVERT($PIECE(userpass,":",2),"i","URL")
				}
				Else { //No : before @
					Set Components("username") = $ZCONVERT(userpass,"i","URL")
				}
				#; Test for IPv6
				Set locopen = $FIND(hostport,"[")
				Set locclosed = $FIND(hostport,"]")
				If (locopen > 0) && (locclosed > 0) && (locopen < locclosed) { //Yes IPv6
					Set Components("host") = $EXTRACT(hostport,locopen,locclosed-2)
					If $EXTRACT(hostport,locclosed,*)[":" { //There's a port after IPv6.
						Set Components("port") = $PIECE($EXTRACT(hostport,locclosed,*),":",2)
					}
				}
				Else { //No IPv6
					Set Components("host") = $PIECE(hostport,":")
					Set Components("port") = $PIECE(hostport,":",2)
				}
			}
			Else { //No credentials. This must be IPv6.
				#; Test for IPv6
				Set locopen = $FIND(netloc,"[")
				Set locclosed = $FIND(netloc,"]")
				Set Components("host") = $EXTRACT(netloc,locopen,locclosed-2)
				If $EXTRACT(hostport,locclosed,*)[":" { //There's a port after IPv6.
					Set Components("port") = $PIECE($EXTRACT(hostport,locclosed,*),":",2)
				}
			}
	 	}
	 	ElseIf tLen > 3 { //More than 2 :
	 		If netloc["@" {
	 			Set userpass = $PIECE(netloc,"@")
				Set $PIECE(netloc,"@") = ""
				Set netloc = $EXTRACT(netloc,2,*)
				
				#; Decompose the userpass variable.
				If userpass[":" {
					Set Components("username") = $ZCONVERT($PIECE(userpass,":"),"i","URL")
					Set $PIECE(userpass,":") = ""
					Set Components("password") = $ZCONVERT($EXTRACT(userpass,2,*),"i","URL")
				}
				Else { //There's no password.
					Set Components("username") = $ZCONVERT(userpass,"i","URL")
				}
	 		}
	 		Set Components("host") = $EXTRACT(netloc,$FIND(netloc,"["),$FIND(netloc,"]")-2)
	 		Set $PIECE(netloc,"]") = ""
	 		Set netloc = $EXTRACT(netloc,2,*)
	 		If netloc '= "" { //There's a port
	 			Set Components("port") = $EXTRACT(netloc,2,*)
	 		}
	 	}
	 } 
	
	#; See if Url contains a fragment. If yes, get it and remove it from Url.
	If Url["#" {
			Set Components("fragment") = $ZCONVERT($PIECE(Url,"#",*),"i","URL")
			Set $EXTRACT(Url,$FIND(Url,"#")-1,*) = ""
		}
		
	#; See if Url contains a query. If yes, get it and remove it from Url.
	If Url["?" {
			Set Components("query") = $ZCONVERT($PIECE(Url,"?",*),"i","URL")
			Set $EXTRACT(Url,$FIND(Url,"?")-1,*) = ""
		}
		
	#; See if Url contains parameters. If yes, get them and remove them from Url.
	If Url[";" {
			Set Components("params") = $ZCONVERT($PIECE(Url,";",*),"i","URL")
			Set $EXTRACT(Url,$FIND(Url,";")-1,*) = ""
		}
		
	#; The path is whatever's left.
	If Url '= "" Set Components("path") = $ZCONVERT(Url,"i","URL")
	
	Quit
}

/// Composes a URL from its Components array as defined by the <METHOD>Decompose</METHOD> method.<br>
/// This method will use Components("netloc"), if defined. To compose a URL with Components("username"), Components("password"), Components("host"), or Components("port"), <br>
/// set Components("netloc") to ""
ClassMethod Compose(ByRef Components As %Library.String) As %Library.String [ Final, ProcedureBlock = 1 ]
{
	Set Url = ""
	If $GET(Components("scheme"),"") '= "" {
		Set Url = Url_$ZCONVERT(Components("scheme"),"o","URL")_":"
		#; File is a special case where you need to add the extra // even thought there's no netloc.
		If Components("scheme") = "file" Set Url = Url_"//"
	}
	If $GET(Components("netloc"),"") '= "" {
		Set Url = Url_"//"_Components("netloc")
	} ElseIf (($GET(Components("username"),"") '= "")||($GET(Components("password"),"") '= "")||($GET(Components("host"),"") '= "")||($GET(Components("port"),"") '= "")) {
		Set Url = Url_"//"
		If $GET(Components("username"),"") '= "" {
			Set Url = Url_Components("username")
			If $GET(Components("password"),"") '= "" {
				Set Url = Url_":"_Components("password")
			} 
			Set Url = Url_"@"
		} 
		If $GET(Components("host"),"") '= "" {
			Set Url = Url_Components("host")
		} 
		If $GET(Components("port"),"") '= "" {
			Set Url = Url_":"_Components("port")
		} 
	}
	If $GET(Components("path"),"") '= "" {
		Set Url = Url_$ZCONVERT(Components("path"),"o","URL")
	}
	If $GET(Components("params"),"") '= "" {
		Set Url = Url_";"_$ZCONVERT(Components("params"),"o","URL")
	}
	If $GET(Components("query"),"") '= "" {
		Set Url = Url_"?"_$ZCONVERT(Components("query"),"o","URL")
	}
	If $GET(Components("fragment"),"") '= "" {
		Set Url = Url_"#"_$ZCONVERT(Components("fragment"),"o","URL")
	}
	Quit Url
}

ClassMethod ParseHost(pHost As %String, ByRef Components As %Library.String) [ Private ]
{
 If pHost["@" {
 Set Components("password")=$Piece(pHost,"@"),Components("host")=$Piece(pHost,"@",2)
 } else {
 Set Components("host")=$piece(pHost,"?")
 }
}

}
