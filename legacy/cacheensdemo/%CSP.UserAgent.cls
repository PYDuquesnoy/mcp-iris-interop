/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Determine browser parameters from HTTP_USER_AGENT CGI variable.
Class %CSP.UserAgent Extends %RegisteredObject [ System = 4 ]
{

/// User agent for this class.	
Property UserAgent As %String;

/// Supports XMLHttpRequest.
Property SupportsXMLHttpRequest As %Boolean;

/// Browser name
Property Browser As %String;

/// Browser platform
Property Platform As %String;

/// Browser version
Property Version As %String;

/// Initialize with HTTP_USER_AGENT.
Method %OnNew(userAgent As %String) As %Status
{
	Set ..UserAgent=userAgent
	Quit $$$OK
}

/// Set method for UserAgent property
Method UserAgentSet(value As %String) As %Status [ Internal ]
{
	#Dim browser,platform,version
	Set i%UserAgent=value
	Set i%SupportsXMLHttpRequest=..XMLHttpRequest(value,.browser,.platform,.version)
	Set i%Browser=browser
	Set i%Platform=platform
	Set i%Version=version
	Quit $$$OK
}

/// XMLHttpRequest returns true if XMLHttpRequest object is supported by the browser indicated by the userAgent.
/// Current implementation parses User Agents beginning with:
/// <table border=1 cellpadding=10>
/// <td>Opera/</td>
/// <td>Browser type is Opera. The version must be greater than or equal to 7.60.</td>
/// </tr><tr>
/// <td>Mozilla/5.0 (</td>
/// <td>If the User Agent contains "Safari/", the browser type is Safari. The version number must be greater 119.0.
/// <br><br>Otherwise the platform type must be one of Windows, Macintosh, or X11 and the User Agent must contain "Gecko/".
/// <br><br>Otherwise User Agent must contain "rv:". The browser type is Mozilla and the version must be greater than 1.3.
/// Camino version 5-- plus browsers listed in exclude-list are not supported.
/// </p></td>
/// </tr>
/// </ul>
ClassMethod XMLHttpRequest(userAgent As %String, ByRef browser As %String, ByRef platform As %String, ByRef version As %String) As %Boolean
{
	#Dim major,minor
	#Dim pos As %Integer
	#Dim start As %String
	#Dim canHandleRequests As %Boolean
	
	// XMLHttpRequest is not supported for any NetCaptor versions.
	If (userAgent["NetCaptor") {
		Quit 0
	}
	
	Set (browser,platform,major,minor,version)=""
	Set canHandleRequests=0

	// Check for Windows IE versions up to IE10.
	Set start="Mozilla/4.0 (compatible; MSIE "
	If start'=$extract(userAgent,1,$length(start)) {
		Set start="Mozilla/5.0 (compatible; MSIE "
		If start'=$extract(userAgent,1,$length(start)) {
			Set start=""
		}
	}
	
	// Check for IE11 and later
	If start="" {
		Set start="Mozilla/5.0 ("
		Set pos=0
		If start=$extract(userAgent,1,$length(start)),userAgent["; Trident/" {
			Set pos=$find(userAgent,"; rv:")
		}
	} Else {
		Set pos=$length(start)+1
	}

	// "" indicates userAgent does not start with a IE string..
	If pos>0 {
		Set browser="IE"
		If userAgent["Win" {
			Set platform="Windows"
			Do ..GetVersion(userAgent,pos,.major,.minor)
			if ( (major=7) && (userAgent["Trident/5" )) {
				Set major = 9
			}
			Set canHandleRequests=(major>=5)
		}
	}
	else {  // try Opera		
		Set start = "Opera/"
		If start=$extract(userAgent,1,$length(start)) {
			Set platform=$piece($piece(userAgent,";",1),"(",2)
			if (platform["Macintosh") {
				Set platform = "Macintosh"
			}
			elseif (platform["Windows") {
				Set platform = "Windows"
			}
			elseif (platform["X11") {
				Set platform = "X11"
			}

			Set browser="Opera"
			Set pos=$find(userAgent,"Version/")
			If pos>0 {
				Do ..GetVersion(userAgent,pos,.major,.minor)
				Set canHandleRequests=(((major=7)&&(minor>=60))||(major>7))
			}
		}
		else {
			Set start="Mozilla/5.0 ("
			If start=$extract(userAgent,1,$length(start)) {
				Set platform=$piece($piece(userAgent,";",1),"(",2)
				if (platform["Macintosh") {
					Set platform = "Macintosh"
				}
				elseif (platform["Windows") {
					Set platform = "Windows"
				}
				elseif (platform["X11") {
					Set platform = "X11"
				}

				// Safari
				Set pos=$find(userAgent,"Safari/")
				If (pos>0) {
					//Set browser = $case(userAgent["Chrome/", 0:"Safari", :"Chrome")
					Set browser = "Safari"
					Do ..GetVersion(userAgent,pos,.major,.minor)
					Set canHandleRequests=(major>=119)
					
					if $case(platform,"Windows":0,"Macintosh":0,"X11":0,:1) {	
						Set platform=$piece(userAgent,"(",2)
						if ( platform["Android") {
							Set platform = "Android"
						}
						elseif (( platform["iPad" )||( platform["iPhone" )) {
							Set platform = "iOS"
						}
						else {
							Set canHandleRequests = 0
						}
					} 
				}		// Check for Gecko rendering engine
			 	elseif ( ($case(platform,"Windows":1,"Macintosh":1,"X11":1,:0) )
					&& (userAgent["Gecko/")) {
					// Netscape 7.x+
					Set pos=$find(userAgent,"Netscape/")
					If pos>0 {
						Set browser="Netscape"
						Do ..GetVersion(userAgent,pos,.major,.minor)
						Set canHandleRequests=(((major=7)&&(minor>0))||(major>7))
					}
					else {			
						// Mozilla and Firebird have rv:1.x and rv:2.x
						Set pos=$find(userAgent,"rv:")
						If pos>0 {
							Set browser="Mozilla"
							Do ..GetVersion(userAgent,pos,.major,.minor)
							If ((major=1)&&(minor>=3))||(major>1) {
								// Do not support AOL, Chimera or Phoenix browser, since will not test
								Set canHandleRequests=1
								If (userAgent["Camino") && (minor<6){
									Set canHandleRequests=0
								}
							}
						}
					}
				}
			}
		}
	}
 	
 	if ( canHandleRequests ) {
	 	// exclude browsers we don't like
		#Dim guysWeDontLike, guy, ua
		#Dim iii As %Integer
		Set guysWeDontLike = "Arora,ABrowse,AOL,Cheshire,Chimera,CometBird,Comodo_Dragon,Conkeror,Deepnet,Firebird,Flock,Fluid,Galeon,GranParadiso,IceCat,Iceweasel"
		Set guysWeDontLike = guysWeDontLike_",Iron,K-Meleon,K-Ninja,Kapiko,KMLite,LeechCraft,lolifox,Lorentz,Lunascape,Madfox,Maxthon,Minefield,myibrow,Namoroka,Navscape,Phoenix"
		Set guysWeDontLike = guysWeDontLike_",OmniWeb,Orca,Palemoon,Phoenix,Pogo,Prism,QtWeb,rekonq,RockMelt,SeaMonkey,Shiira,Shiretoko,Stainless,Sunrise,Sylera,Vonkeror,WeltweitimnetzBrowser,Wyzo"
		// mobile browsers
		Set guysWeDontLike = guysWeDontLike_",BlackBerry,Bolt,Dorothy,Fennec,Iris,Maemo Browser,Minimo,Opera Mini,Skyfire,TeaShark"
		Set guysWeDontLike = $zcvt(guysWeDontLike,"U")

		Set ua = $zcvt(userAgent,"U")
		For iii=1:1:$length(guysWeDontLike,",") {
			Set guy = $piece(guysWeDontLike,",",iii)
			if ( ua[guy ) {
				Set canHandleRequests = 0
				Quit
			}
		}
		
	 	If browser'="" {
		 	Set version=major_"."_minor
 		}	
 	}

	$$$SysLogVar(2,"CSPUserAgent","Browser: "_browser_" "_platform_" v"_version,userAgent)
	Quit canHandleRequests
}

/// Extract version information from specified start position as major.minor
ClassMethod GetVersion(version As %String, pos As %Integer, ByRef major As %String, ByRef minor As %String) [ Internal ]
{
	#Dim zero,nine,ch
	#Dim i as %Integer
	
	Set zero=$ascii("0",1)
	Set nine=$ascii("9",1)
	Set (major,minor)=0
	For i=pos:1:$length(version) {
		Set ch=$ascii(version,i)
		If (ch<zero) || (ch>nine) Quit
		Set major=10*major+ch-zero
	}
	If $extract(version,i)'="." Quit
	For i=i+1:1:$length(version) {
		Set ch=$ascii(version,i)
		If (ch<zero) || (ch>nine) Quit
		Set minor=10*minor+ch-zero
	}
}

}
