/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %WebStress.Record [ Abstract, System = 4 ]
{

/// 
/// Entry here to start a recording.<br>
/// 
/// Scriptname is a unique text<br>
/// 
/// browserPort is the port that this recording 'proxy' will listen on<br>
/// 
/// readTimeOut is the number of seconds to wait for responses from the web servers<br>
/// 
/// rtnName is the prefix that will be used for the ObjectScript routines when the randomisation routines are created for the script.
/// debug will cause the main controlling program to output to the principal device<br>
ClassMethod Run(scriptName As %String, browserPort As %Integer = 8080, rtnName As %String = "", readTimeout As %Integer = 10, TokenMode As %Boolean = 0, debug As %Boolean = 0) As %String
{
	set msg=""
	do {
		lock +^WebStress.Record:0 if '$test set msg="Could not lock the recording data area" quit
		kill ^WebStress.Record
		// shouldn't really need this! Do $ZU(68,57,1)  ;Turn on PSW2NOTHROTTLE bit to bypass throttle
		set ^WebStress.Record("BrowserPort")=browserPort
		set ^WebStress.Record("Script")=scriptName
		
		// We've setup all the parameters, now go and wait for the browser to send requests
		do ..ConnectRead(browserPort,readTimeout,debug)
		
		// All finished recording, store the results away in %WebStress.Scripts
		set msg = ##class(%WebStress.Scripts).CacheRecorder(scriptName,1,rtnName)
		
		lock -^WebStress.Record
	} while 0
	quit msg
}

/// 
/// This is where we sit on the specified port number and wait for the connections to come through from the browser<br>
ClassMethod ConnectRead(browserPort As %Integer, readTimeout As %Integer, debug As %Boolean = 0)
{
	// Initialise the global so that the stop signal is reset
	Set ^WebStress.Record("Shutdown")=0
	
	// Setup the device that we'll listen on
	set connectDevice="|TCP|"_browserPort
	if debug write !,"Waiting for connections on ",connectDevice,":",browserPort
	close connectDevice
	open connectDevice:(:browserPort:"SA"::8192:8192:10:/TCPNOXY):4 set ok=$test
	if 'ok quit
	use connectDevice
	
	// Turn off translation for input and output so that we are in raw mode
	Do $zu(125,6,"",0,3,0),$zu(125,6,"",1,3,0)
	For  {
		// Continually loop waiting for something to connect to us
		try {
			for  Read connect:1 quit:$test  if ^WebStress.Record("Shutdown")=1 quit
			if ^WebStress.Record("Shutdown")=1 set ^WebStress.Record("Shutdown")=2 quit
			// Increment the main counter number. This will be used to key the requests/responses
			set pNumber=$i(^WebStress.Record)
			// Store the request time
			set ^WebStress.Record(pNumber)=$zh
			if debug use $p write !,"Got connection #",pNumber use connectDevice
			// Start a separate process to handle this request from the browser
			Job ..BrowserRead(browserPort,pNumber,readTimeout):(:65560):20 If '$Test write *-2
		}
		catch {
			quit
		}
		if ^WebStress.Record("Shutdown") quit
	}
	close connectDevice
}

/// 
/// Get the actual request content from the browser for one specific request
ClassMethod BrowserRead(browserPort As %Integer, pNumber As %Integer, readTimeout As %Integer)
{
	Use $ZU(53):(::"SA"::8192:8192)
	set counter=0
	// Turn off input and output translation
	Do $zu(125,6,"",0,3,0),$zu(125,6,"",1,3,0)
	try {
		for {
			// We have to keep looping here as there might be more than one request/connection
			s st=$zh
			read hdr#4:0.1
			s tm=$zh-st
			if '$test quit
			// We can get all manner of strange things so only process GETs and POSTs
			if (hdr="GET ")||(hdr="POST") {
				set counter=counter+1
				if counter>1 set pNumber=pNumber+1
				Do $zu(132)
				Set IO=$G(IO,$S($ZU(53)'="""":$ZU(53),1:$IO))
				Use IO:(::"A")  ; Reset default parameters
				Use IO:(::"+D")
				// Now get the main part of the request
				read rq#30000:0
				set rq=hdr_rq
				// Store the request in the record global
				set ^WebStress.Record(pNumber,"read",1)=rq
				if $piece(rq," ",1)="POST" {
					// There could well be lots of formdata in a POST so keep reading the request data if required
					set contentLength=+$piece(rq,"Content-Length: ",2)-$length($piece(rq,$char(13,10,13,10),2))
					set moreLength=contentLength,counter=1
					while (moreLength>0) {
						set readLength=moreLength
						if readLength>20000 set readLength=20000
						read postData#readLength:1
						if '$test quit
						set counter=counter+1
						set ^WebStress.Record(pNumber,"read",counter)=postData
						set moreLength=moreLength-$length(postData)
					}
				}
				// Send the request to the server
				do ..Server(pNumber,readTimeout)
				Use IO:(::"SCWD"::8192:8192)
				// Write the server response back to the browser
				for i=1:1 quit:'$data(^WebStress.Record(pNumber,"write",i))  write ^(i)
				write *-3
				// Store the time now
				set ^WebStress.Record(pNumber,"timed")=($zh-^WebStress.Record(pNumber))
				close IO
			}
		}
	}
	catch {
		if $zerror'["<READ>" {
			set ^WebStress.Record(pNumber,"error") = $zerror
		}
	}
}

/// 
/// This is where we send a specific request to the web server and get the responses<br>
ClassMethod Server(pNumber As %Integer, readTimeout As %Integer)
{
	// Setup list of headers to be ignored
	set ignore("Host")= ""
	set ignore("Proxy-Connection") = ""
	set ignore("Referer") = ""
	set ignore("User-Agent") = ""
	set ignore("Content-Length") = ""
	
	// Use the %Net.HttpRequest object as it makes most things easier
	// Get the first line. This will have the address, headers, etc
	set data = $piece(^WebStress.Record(pNumber,"read",1),$char(13,10),1)
	set verb = $piece(data," ",1)
	set serverAddr = $piece(data,"/",3)
	set page = $piece($piece(data,"?",1)," ",2)
	set page = "/"_$piece(page,"/",4,99)
	set params = $piece(data,"?",2,99)
	if $extract(params,$length(params) - 8) = " " set params = $extract(params,1,$length(params)-9)
	set serverPort = $piece(serverAddr,":",2),serverAddr=$piece(serverAddr,":",1)
	if serverPort = "" set serverPort=80
	
	// Initialise the object and put the headers in from the browser request
	set objHttp = ##class(%Net.HttpRequest).%New()
	set objHttp.Server = serverAddr
	set objHttp.Port = serverPort
	set data = ^WebStress.Record(pNumber,"read",1)
	set headers = $piece(data,$char(13,10,13,10),1)
	set len = $length(headers,$char(13,10))
	for i = 2:1:len {
		set info = $piece(headers,$char(13,10),i)
		if info = "" quit
		set hdr = $piece(info,":",1)
		set value = ##class(%CSP.Page).UnescapeURL($piece(info,": ",2))
		if hdr="User-Agent" {
			set objHttp.UserAgent=value
		}
		if hdr="Referer" {
			set objHttp.Referer=value
		}
		if (hdr '= "")&&('$data(ignore(hdr))) do objHttp.SetHeader(hdr,value)
	}
	
	// Now add in the parameters that came in the URL from the browser
	set len = $length(params,"&"),paracount=0
	for i = 1:1:len {
		set param = $piece(params,"&",i)
		set name = $piece(param,"=",1),value = ##class(%CSP.Page).UnescapeURL($piece(param,"=",2,99))
		if name '= "" {
			set x=$i(paracount(name))
			do objHttp.SetParam(name,value,x)
		}
	}
	kill paracount
	// Now check for form data (normally as part of a POST)
	set formData = $piece(data,$char(13,10,13,10),2)
	// 'next' is the pointer to the next global entry in the 'read' (request from browser) subscript
	set next = 2
	for i=1:1 {
		// Keep checking if there is more form data that we can append to the end of what we already have
		if $data(^WebStress.Record(pNumber,"read",next)) {
			if ($length(formData) + $length(^WebStress.Record(pNumber,"read",next))) < 30000 {
				set formData = formData_^WebStress.Record(pNumber,"read",next)
				// Increment the pointer value
				set next = next + 1
			}
		}
		set param = $piece(formData,"&",1)
		if param = "" quit
		set formData = $piece(formData,"&",2,999)
		set name = $piece(param,"=",1)
		set value = ##class(%CSP.Page).UnescapeURL($piece(param,"=",2,999))
		if name '= "" {
			set name=##class(%CSP.Page).UnescapeURL(name)
			do objHttp.InsertFormData(name,value)
		}
	}
	
	// Now send the request to the server
	if verb = "GET" {
		set status = objHttp.Get(page)
	}
	elseif verb = "POST" {
		set status = objHttp.Post(page)
	}
	if status {
		// We got a good status. Now we have to store the response. This will then be written back to the browser
		set data = objHttp.HttpResponse.StatusLine
		// Loop down all the headers and put those in
		set hdr = ""
		for  {
			set hdr = $order(objHttp.HttpResponse.Headers(hdr))
			if hdr = "" quit
			set value = objHttp.HttpResponse.Headers(hdr)
			set header = hdr
			// The object builds up a stream object (.Data) from the response and therefore
			// removes all the 'chunk' information. We therefore have to remove the 'chunk' header
			// and return the content as 'content-length'
			if (hdr = "TRANSFER-ENCODING")&&(value = "chunked") set header = "CONTENT-LENGTH"

			// Definately do not want the browser to think that the content is gzip compressed 'cos it is now in plain text
			if (hdr = "CONTENT-ENCODING")&&(value = "gzip") set header = ""

			// Make sure that the content length is the correct value
			if header = "CONTENT-LENGTH" set value = objHttp.HttpResponse.Data.Size
			
			// Put the header and its value into the stream but build up an array of headers so we can check them later
			if header '= "" {
				set data = data_$char(13,10)_header_": "_value
				set hdr(header) = value
			}
		}
		// If we didn't get a content length in the headers then put it in now
		if '$data(hdr("CONTENT-LENGTH")) set data = data_$char(13,10)_"CONTENT-LENGTH: "_objHttp.HttpResponse.Data.Size
		
		// Put in a double CRLF and then put in all the page data
		set data = data_$char(13,10,13,10)
		set ^WebStress.Record(pNumber,"write",1) = data
		for i = 2:1 {
			set len = 8192
			set data = objHttp.HttpResponse.Data.Read(.len)
			set ^WebStress.Record(pNumber,"write",i) = data
			if objHttp.HttpResponse.Data.AtEnd quit
		}
	}
}

}
