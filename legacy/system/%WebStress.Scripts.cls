/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// These are the recorded scripts that will be played back against the test system
Class %WebStress.Scripts Extends (%Persistent, %XML.Adaptor, %ZEN.DataModel.Adaptor) [ ClassType = persistent, Inheritance = right, Owner = {%Developer}, ProcedureBlock, System = 4 ]
{

Parameter FileTimestamp = "60009,39315";

/// This is the default port that is used to communicate with the web server. It is assumed to be 80 unless otherwise specified.
/// <br>
/// It can be overridden by any URL
Property OriginalPort As %String(TRUNCATE = 1) [ InitialExpression = 80 ];

/// This is the default web server address that will be used throughout the script.
/// <br>
/// It is taken from the first URL call.
/// <br>
/// The reason that we store it is so that it can be retrieved if any of the URLs throughout the script call other web servers
/// <br>
/// when it is overridden by that particular URL
Property OriginalServer As %String(TRUNCATE = 1);

/// The code to call to see if the returned page was an error.
/// This should in the form of a function that returns a zero or non-zero value where zero = no errors and non-zero = errors found
/// <br>
/// Examples:
/// <br>
/// $$IsError^MyScript()
/// <br>
/// ##class(User.Script).IsError()
Property ErrorCheck As %String(TRUNCATE = 1);

/// A unique name for this script
Property Name As %String(TRUNCATE = 1);

/// The is the code that is executed before each run of the script.
/// It should take the form of a function that returns a zero or non-zero value indicating
/// whether the script can run or not. (Zero = do not run, non-zero = run script)
/// <br>
/// Examples:
/// <br>
/// $$Init^MyScript()
/// <br>
/// ##class(User.Script).Init()
Property PreRunCode As %String(MAXLEN = 256, TRUNCATE = 1);

/// The is the code that is executed at the end of each full script
/// It should take the form of a function that returns a zero or non-zero value indicating
/// whether the script should continue to run or not. (Zero = stop running, non-zero = continue to run the script)
/// <br>
/// Examples:
/// <br>
/// $$AtEnd^MyScript()
/// <br>
/// ##class(User.Script).AtEnd()
Property PostRunCode As %String(MAXLEN = 256, TRUNCATE = 1);

/// A calculation of how long the script would take to run based upon the delay time
/// between the user's input and the recorded length of time for the server to reply to
/// the request.
Property TotalLengthMins As %Numeric [ Calculated, SqlComputeCode = {	set {TotalLengthMins}=##class(%WebStress.Scripts).GetTotalLengthMins({ID})}, SqlComputed ];

/// These are the details of each dialog between the browser and the web server 
/// that all go together to form the total script.
Relationship URLs As %WebStress.Scripts.URLS [ Cardinality = children, Inverse = Script ];

/// This indicates the method used to build this script
Property RecordMethod As %String(TRUNCATE = 1) [ InitialExpression = "Manual" ];

/// The name of the routine that contains the randomisation code
Property RandomisationRoutine As %String(TRUNCATE = 1);

/// The date/time that the randomisation routine was automatically generated
Property RandomisationGenTime As %Integer;

/// Indicates whether one or more of the URLs for this script contains a CSPToken (protected/encrypted page)
Property ContainsCSPToken As %Boolean;

/// Date and time that this script was recorded
Property RecordDateTime As %TimeStamp;

Method TotalLengthMinsGet() As %Numeric
{
 quit ..GetTotalLengthMins(..%Id())
}

Method HomeDirectory() As %String
{
	quit $zu(12,"")
}

Index NameIndex On Name [ Unique ];

ClassMethod GetTotalLengthMins(id As %String)
{
	&sql(select (sum(Delay)+sum(RecordedTime)) into :total from %WebStress_Scripts.URLs where Script = :id)
	quit $j(total/1000/60,0,2)
}

/// This method can be called to automatically create the base routine for randomisation scripts.
/// It accepts two arguments:
/// <br>
/// scriptid	=	This is the internal ID number of the script. (Required)
/// rtnname		=	This is the name of the routine. (Optional). If not present this will default to "Random.Script.<i>n</i>"
/// <br>
/// where <i>n</i> is the <i>scriptid</i> number
ClassMethod MakeRtn(scriptid As %Integer, rtnName As %String = "") As %String
{
	set script = ##class(%WebStress.Scripts).%OpenId(scriptid)
	if '$IsObject(script) quit ""
	set sep = $char(9)
	if rtnName = "" set rtnName = "Random.Script."_scriptid
	set rtn = ##class(%Library.Routine).%New(rtnName_".MAC")
	do rtn.WriteLine($tr(rtnName,".")_sep_"// Random parameters for "_script.Name)
	do rtn.WriteLine(sep_"// Generated on "_$zdt($h,3))
	do rtn.WriteLine(sep_"quit")
	do rtn.WriteLine("")
	
	set urlcount = script.URLs.Count()
	set saveflag = 0
	for url = 1:1:urlcount {
		set paramcount = script.URLs.GetAt(url).Parameters.Count()
		if paramcount > 0 {
			do rtn.WriteLine("PreURL"_url_sep_"// "_script.URLs.GetAt(url).Verb_" "_script.URLs.GetAt(url).Path)
			if script.URLs.GetAt(url).Description '= "" do rtn.WriteLine(sep_"// "_script.URLs.GetAt(url).Description)
			kill names
			for param = 1:1:paramcount {
				set name = script.URLs.GetAt(url).Parameters.GetAt(param).Key
				set value = script.URLs.GetAt(url).Parameters.GetAt(param).Value
				set type = script.URLs.GetAt(url).Parameters.GetAt(param).Type
				if (type'="S") {
					set index = $i(names(name))
					if value[$char(13,10) {
						set len=$length(value,$char(13,10))
						for i=1:1:len {
							if i=1 {
								do rtn.WriteLine(sep_"set params("""_name_""","_index_")="""_$piece(value,$char(13,10),1)_"""_$char(13,10)")
							}
							else {
								do rtn.WriteLine(sep_"set params("""_name_""","_index_")=params("""_name_""","_index_")_"""_$piece(value,$char(13,10),i)_"""_$char(13,10)")
							}
						}
					}
					else {
						// TP: if parameter is TPAGID then change all to get unique number
						if name="TPAGID" {
							do rtn.WriteLine(sep_"set params("""_name_""","_index_")=$i(^WebStress.Unique)")
						}
						else {
							if value["""" {
								set f = 0, temp = ""
								do {
									set prv = f
									set f = $find(value,"""",f)
									if f {
										set temp = temp_$extract(value,prv,f-1)_""""
									}
									else {
										set temp = temp_$extract(value,prv,$length(value))
									}
								} while f
								set value = temp
							}
							do rtn.WriteLine(sep_"set params("""_name_""","_index_")="""_value_"""")
						}
					}
				}
				else {
					if script.URLs.GetAt(url).Parameters.GetAt(param).PostStream.IsCharacter() {
						do rtn.WriteLine(sep_"set params(""postStream"")=##class(%GlobalCharacterStream).%New()")
					}
					else {
						do rtn.WriteLine(sep_"set params(""postStream"")=##class(%GlobalBinaryStream).%New()")
					}
					do rtn.WriteLine(sep_"do params(""postStream"").CopyFrom(##class(%WebStress.Scripts.URLS.Parameters).%OpenId("""_script.URLs.GetAt(url).Parameters.GetAt(param).%Id()_""",0).PostStream)")
				}
			}
			do rtn.WriteLine(sep_"quit")
			do rtn.WriteLine("")
			set script.URLs.GetAt(url).PreExecute="do PreURL"_url_"^"_rtnName
			set saveflag = 1
		}
	}
	if saveflag do script.%Save()
	set sc = 0
	if rtn.Save() {
		set sc = rtn.Compile("-d")
	}
	if sc {
		set objScript=##class(%WebStress.Scripts).%OpenId(scriptid)
		set objScript.RandomisationRoutine=rtn.Name
		set rtnDate=##class(%Library.Routine).GetDate(rtn.Name_".obj")
		set rtnDate=$zdth(rtnDate,3)
		set rtnDate=rtnDate*86400+$piece(rtnDate,",",2)
		set objScript.RandomisationGenTime=rtnDate
		do objScript.%Save()
		quit rtn.Name
	}
	quit sc
}

/// Converts the output from a recorded session into a script with associated URLs etc.
/// <br>
/// Requires a script name as a parameter. Note that this is stored in the recorded data 
/// after this method has been called meaning that subsequent calls to this method can be
/// left blank and the method will re-use the last supplied name.
/// <br>
/// creatertn is either 0 (zero) or non-zero indicating whether or not an automatic randomisation base routine
/// is to be created.
/// <br>
/// rtnname specifies the optional routine name if creatrtn is used.
ClassMethod CacheRecorder(scriptname As %String = "", creatertn As %Integer = 0, rtnname As %String = "", debug As %Boolean = 0) As %String
{
	// First check that we can do something
	lock +^WebStress.Record:0 set ok=$test
	if 'ok quit "Couldn't lock the proxy global data"
	if scriptname="" set scriptname=$get(^WebStress.Record("ScriptName"))
	if scriptname="" set scriptname="New Script - "_$zdt($h,3)
	if $order(^WebStress.Record(""))'?1n.n lock -^WebStress.Record quit "No data in the proxy global"
	
	// now find out if we're dealing with an existing script
	&sql(select ID into :ID from %WebStress.Scripts where Name = :scriptname)
	if SQLCODE=0 {
		set obj = ##class(%WebStress.Scripts).%OpenId(ID)
		if obj = "" lock -^WebStress.Record quit "Couldn't open existing script #"_ID
		if debug do ..ShowProgress("Deleting existing script: "_scriptname)
		&sql(delete from %WebStress_Scripts.URLs where Script = :ID)
	}
	else {
		set obj = ##class(%WebStress.Scripts).%New()
		set obj.Name = scriptname
		set obj.RecordDateTime = $zdatetime($horolog,3)
	}

	set obj.RecordMethod = "Recorder"	
	// Now scan down the recorded information
	set pNumber = "",time=""
	for  {
		set pTime=time,pNumber = $order(^WebStress.Record(pNumber),1,time)
		if pNumber'?1n.n quit
		if $data(^WebStress.Record(pNumber,"read",1)) {
			if debug do ..ShowProgress("Processing #"_pNumber)
			// Got one so build up a new URL instance
			set url=##class(%WebStress.Scripts.URLS).%New()
			set url.Script = obj
			// Work out the delay time between the calls
			if pTime'="" {
				set delay=time-pTime
				set url.Delay=$justify((delay*1000),0,0)
				set url.RecordedTime=$justify($get(^WebStress.Record(pNumber,"timed"))*1000,0,0)
			}
			
			// Now get the request sent from the browser
			set url.Request=##class(%GlobalCharacterStream).%New()
			set key="",null=0,contentType=""
			for  {
				set prev=key,key=$order(^WebStress.Record(pNumber,"read",key),1,data)
				if key="" quit
				// Build up the stream object that will contain the original request
				do url.Request.Write(data)
				if prev="" {
					// The first line should contain the header information
					// Any subsequent lines are continuations
					set verb=$piece(data," ",1)
					set url.Verb = verb
					// Now get the actual call
					set path=$piece($piece(data," ",2),"?",1)
					set len=$length(path,"/")
					// Now get the base path, ignoring the server id
					set url.Path="/"_$piece(path,"/",4,len)
					// Find the page suffix so that we can indicate whether this is the start of a page 'group'
					set len=$length(url.Path,".")
					if len=1 {
						set url.PageMarker=1
					}
					else {
						set url.PageMarker=0
						set suffix=$zcvt($piece(url.Path,".",len),"l")
						if (suffix?1a1"sp")||(suffix?1"htm".e)||(suffix="cls") set url.PageMarker=1
					}
					// Now get the server id
					set server=$piece(path,"/",3)
					// Protocol
					set url.Protocol=$piece($piece(data,$char(13,10),1)," ",3)
					// We may have to deal with explicit port numbers
					if pNumber=1 {
						set obj.OriginalServer=$piece(server,":",1)
						set obj.OriginalPort=$piece(server,":",2)
					}
					if $piece(server,":",2)'="" set url.SpecifiedPort=$piece(server,":",2)
					if $piece(server,":",1)'=obj.OriginalServer set url.ServerChange=$piece(server,":",1)
					
					// If we're on the first readable line then the headers should be in here
					if 'null {
						set start=1
						if key=1 set start=2
						set len=$length(data,$char(13,10))
						for i=start:1:len {
							if $piece(data,$char(13,10),i)="" set null=1 quit
							set head=$piece(data,$char(13,10),i)
							set hLen=$length(head," ")
							set hdr=$piece(head," ",1),info=$piece(head," ",2,hLen)
							if $zcvt(hdr,"l")="content-type:" set contentType=$zcvt(info,"l")
							if $zcvt(hdr,"l")="content-length:" set contentLength=info
							if hdr'="" do url.Headers.SetAt(info,hdr)
						}
					}
 // Now get the parameters
 if (contentType'="text/xml") {
	set params=$piece($piece(data," ",2),"?",2)
	if params'="" {
		set len=$length(params,"&")
		for i=1:1:len {
			set paramKey=##class(%CSP.Page).UnescapeURL($piece($piece(params,"&",i),"=",1))
			// TP: Record a new parameter instance only if Key is not blank
			if ($g(paramKey)'="")&&($g(paramKey)'="CSPCHD") {	
				set param=##class(%WebStress.Scripts.URLS.Parameters).%New()
				// Point it back at the URL and default its type to 'P' (parameter, instead of (F)orm)
				set param.URL=url,param.Type="P"
				set param.Key=paramKey
				set param.Value=##class(%CSP.Page).UnescapeURL($piece($piece(params,"&",i),"=",2))
				set sc=param.%Save()
			}
			if 'sc break
		}
	}
}

				}

				// Anything after that should be the form data
				set len=$length(data,$char(13,10))
				
				if (contentType="text/xml") {
					if (prev="") {
						// Create a new parameter instance
						set postStream=##class(%WebStress.Scripts.URLS.Parameters).%New()
						set postStream.URL=url,postStream.Type="S",postStream.Value="[stream]"
						set postStream.PostStream=##class(%GlobalCharacterStream).%New()
						do postStream.PostStream.Write($piece(data,$char(13,10),len))
					}
					else {
						set postStream=##class(%WebStress.Scripts.URLS.Parameters).%OpenId(postStreamId)
						// Probably need the code below when we get to 5.1 and its stream cloning!!!
						//set postStreamMore=##class(%GlobalCharacterStream).%New()
						//do postStreamMore.CopyFrom(postStream.PostStream)
						//do postStreamMore.MoveToEnd()
						//do postStreamMore.Write(data)
						//do postStream.PostStream.Clear()
						//do postStream.PostStream.CopyFrom(postStreamMore)
						do postStream.MoveToEnd()
						do postStream.Write(data)
					}
					set sc=postStream.%Save()
					if sc {
						set postStreamId=postStream.%Id()
						kill postStream
					}
					else {
						//Write it out for the moment so that the debug record from the terminal can see it
						write "Poststream save: " do $system.OBJ.DisplayError(sc)
					}
				}
				elseif (contentType["multipart/") {
					if (prev="") {
						set multipartType=$piece($piece(contentType,"multipart/",2),";",1)
						set boundary=$piece($piece(contentType,"boundary=",2),";",1)
						set postStream=##class(%WebStress.Scripts.URLS.Parameters).%New()
						set postStream.URL=url,postStream.Type="S",postStream.Value="[stream]"
						set postStream.PostStreamBoundary = boundary
						set postStream.PostStream=##class(%GlobalCharacterStream).%New()
						set streamLen = $length(data,boundary)
						set fileStream = $piece(data,boundary,3)
						set postStream.PostStreamName = $piece($piece($piece(fileStream," name=",2),$char(13,10),1),";",1)
						set postStream.PostStreamFilename = $piece($piece($piece(fileStream," filename=",2),$char(13,10),1),";",1)
						set postStream.PostStreamContentType = $piece($piece($piece(fileStream,"Content-Type: ",2),$char(13,10),1),";",1)
						set fileStream=$piece($piece(fileStream,$char(13,10,13,10),2),boundary,1)
						do postStream.PostStream.Write(fileStream)
					}
					else {
						set postStream=##class(%WebStress.Scripts.URLS.Parameters).%OpenId(postStreamId)
						// Probably need the code below when we get to 5.1 and its stream cloning!!!
						//set postStreamMore=##class(%GlobalCharacterStream).%New()
						//do postStreamMore.CopyFrom(postStream.PostStream)
						//do postStreamMore.MoveToEnd()
						//do postStreamMore.Write(data)
						//do postStream.PostStream.Clear()
						//do postStream.PostStream.CopyFrom(postStreamMore)
						do postStream.MoveToEnd()
						do postStream.Write($piece(data,boundary,1))
					}
					set sc=postStream.%Save()
					if sc {
						set postStreamId=postStream.%Id()
						kill postStream
					}
					else {
						// Write it out again
						write "Postream save #2: " do $system.OBJ.DisplayError(sc)
					}
				}
				else {
					set params=$piece(data,$char(13,10,13,10),2)
					if params'="" {
						set params=$piece(params,$char(13,10),1)
						//break
						set len=$length(params,"&")
						for i=1:1:len {
							if ##class(%CSP.Page).UnescapeURL($piece($piece(params,"&",i),"=",1)) '= "CSPCHD" {
								set param=##class(%WebStress.Scripts.URLS.Parameters).%New()
								set param.URL=url,param.Type="F"
								set param.Key=##class(%CSP.Page).UnescapeURL($piece($piece(params,"&",i),"=",1))
								set param.Value=##class(%CSP.Page).UnescapeURL($piece($piece(params,"&",i),"=",2))
								set sc=param.%Save()
								if 'sc break
							}
						}
					}
				}
			}
			// Now get the responses from the server and put them into the response stream object
			set url.Response=##class(%GlobalCharacterStream).%New()
			set key = ""
			for  {
				set key=$order(^WebStress.Record(pNumber,"write",key),1,data)
				if key="" quit
				do url.Response.Write(data)
			}
			set sc=url.%Save()
			if 'sc break
		}
	}
	set sc=obj.%Save()
	if 'sc break
	set msg="Created script '"_scriptname_"' with ID# "_obj.%Id()
	if creatertn {
		set msg=msg_$char(13,10)_"Created randomisation routine: "_##class(%WebStress.Scripts).MakeRtn(obj.%Id(),rtnname)
	}
	set ^WebStress.Record("ScriptName")=scriptname
	lock -^WebStress.Record
	quit msg
}

/// Gets data from MS Access and builds our scripts
/// <br>
/// First you need to follow these steps:
/// <br>
/// 1. Setup a SYSTEM ODBC data source and use the Microsoft Access driver to point to the .mdb file created by the Microsoft tool
/// <br>
/// 2. Setup a SQL Gateway to point towards this ODBC data source
/// <br>
/// 3. Use the SQL Manager to link to the following tables in the .mdb file:
/// <br>
/// 		(a) Groups
/// <br>
/// 		(b) HTTPTransactions
/// <br>
/// 		(c) Scripts
/// <br>
/// These 3 steps should create the following classes:
/// <br>
/// 		(a) %WebStress.WAST.Groups
/// <br>
/// 		(b) %WebStress.WAST.HTTPTransactions
/// <br>
/// 		(c) %WebStress.WAST.Scripts
/// <br>
/// Normally the name of the script would come from the .mdb file but a default can be supplied for the
/// cases where the value in the .mdb file is a null string. In this case the name of the script will be
/// the name of the default name prefix and then the group ID number
/// <br>
/// For example: if defaultnameprefix = "Default_" and the group ID is 3 then the name of the script
/// would be 'Default_3'
/// <br>
/// The overwrite key is used so that you can overcome the problem where MS Access lets two different
/// scripts have the same name. a ' (n)' is added to the end of the script name if overwrite is set to 0
/// <br>
/// For example the first file might be "Main Test" and the second would be "Main Test (2)"
ClassMethod MS2Cache(defaultnameprefix As %String = "Default_", overwrite As %Boolean = 1) As %String
{
	set msg = ""
	do {	
		// Use the result set query to get the data from the other database
		set rs=##class(%ResultSet).%New("%DynamicQuery.SQL")
		if rs=$$$NULLOREF set msg="Couldn't create 'GetData' result set." quit
		set myquery="SELECT Color,Data,GroupID,HasCGIFields,HTTPVersion,Port,RDSConnectionString,RDSQueryString,RequestDelay,SSLType,TransactionID,URL,UseRDS,UseSSL,UseStaticHeadersOnly,Verb FROM %WebStress_WAST.HTTPTransactions ORDER BY GroupID ASC,TransactionID DESC"
		do rs.Prepare(myquery)
		set sc = rs.Execute()
		if 'sc set msg="Couldn't execute 'GetData' result set. "_sc quit
		set group=""
		while rs.Next()
		{
			// If we have a new group then we need to save anything we already have and then have a new script
			if rs.Get("GroupID")'=group {
				if group'="" {
					if script.%Save() {
						set save(script.%Id())=1
					}
					else {
						set save(0)=$i(save(0))
					}
					kill script, scripturl, scriptparams
				}
				set group=rs.Get("GroupID")
				// Get the remote name for the script
				s ref=##class(%ResultSet).%New("%DynamicQuery.SQL")
				set query="SELECT Groups.Name,Scripts.Name from %WebStress_WAST.Groups Groups, %WebStress_WAST.HTTPTransactions HTTPTransactions, %WebStress_WAST.Scripts Scripts WHERE Groups.GroupID =? AND Scripts.ScriptID = Groups.ScriptID)"
				do ref.Prepare(query)
				do ref.Execute(group)
				if ref.Next {
					if (ref.GetData(1)="")||($zcvt(ref.GetData(1),"1")="default") {
						set name=scrname
					}
					else {
						set name=grpname
					}
						
				}
				else {
					// No name found in the other database so use the default
					set name=defaultnameprefix_group
				}
				// Check to see if the name exists. Delete and overwrite if necessary, or change the name
				if overwrite {
					&sql(select ID into :existsid from %WebStress.Scripts where Name = :name)
					if SQLCODE = 0 {
						&sql(delete from %WebStress_Scripts.URLs where script = :existsid)
						set script = ##class(%WebStress.Script).%OpenId(existsid)
					}
					else {
						// New script
						set script=##class(%WebStress.Script).%New()
					}
				}
				else {
					for i=2:1 {
						set findname=name_" ("_i_")"
						&sql(select ID from %WebStress.Scripts where name=:findname)
						if SQLCODE'=0 set name=findname quit
					}
					// New script
					set script=##class(%WebStress.Script).%New()
				}
				
				set script.Name=name
				
				set script.RecordMethod = "Microsoft WAST"
				
			}
			set url=rs.Get("URL"),verb=rs.Get("Verb"),delay=rs.Get("RequestDelay"),data=rs.Get("Data")
			set paramcount=0
			kill params
			// Get any parameters from the URL
			if url["?" {
				set params=$piece(url,"?",$length(url,"?"))
				set url=$piece(url,"?",1)
				for i=1:1:$length(params,"&") {
					set key=$piece($piece(params,"&",i),"=",1)
					set value=$piece($piece(params,"&",i),"=",2)
					if key'="" {
						set paramcount=paramcount+1
						set params(paramcount,"key")=key
						set params(paramcount,"value")=value
						set params(paramcount,"type")="P"
					}
				}
			}
			// Add a new URL to this script
			set scripturl=##class(%WebStress.URLs).%New()
			set scripturl.Script=script
			// Now get the parameters from any formdata
			// This could be tricky as it comes as a long string of hex numbers
			// (It was a 'LONG BINARY' in MS Access)
			set formdata=""
			// Get 'pairs' of numbers
			for i=1:2:$length(data) {
				// Convert from hexadeciaml to decimal
				set hx=$extract(data,i,i+1)
				set dc=$zh(hx)
				// Build up the new string with 'proper' characters
				set formdata=formdata_$char(dc)
			}
			// Now get the parameters from the re-constructed formdata
			for i=1:1:$length(formdata,"&") {
				set key=$piece($piece(formdata,"&",i),"=",1)
				set value=$piece($piece(formdata,"&",i),"=",2)
				if key'="" {
					set paramcount=paramcount+1
					set params(paramcount,"key")=key
					set params(paramcount,"value")=value
					set params(paramcount,"type")="F"
				}
			}
			set scripturl.Path=url,scripturl.Verb=verb,scripturl.Delay=delay
			for i=1:1:paramcount {
				// Add a new parameter to this URL
				set scriptparams=##class(%WebStress.Scripts.URLS.Parameters).%New()
				set scriptparams.URL=scripturl
				set scriptparams.Key=params(i,"key")
				set scriptparams.Value=##class(%CSP.Page).UnescapeURL(params(i,"value"))
				set scriptparams.Type=params(i,"type")
			}
		}
		// Save any open script at the end of getting the data from MS Access
		if script.%Save() {
			set save(script.%Id())=script.Name
		}
		else {
			set save(0)=$i(save(0))
		}
		do rs.Close()
	} while 0
	if msg = "" {
		if $get(save(0))>0 set msg=save(0)_" script(s) failed to save. "
		write "The following scripts were saved:",!
		set sb = 0
		for i=1:1 set sb=$order(save(sb)) quit:sb=""  write save(sb),!
		set msg=msg_(i-1)_" scripts were saved."
	}
	quit msg
}

ClassMethod CheckRoutineIsValid(id As %String) As %Boolean
{
	&sql(select RandomisationRoutine, RandomisationGenTime into :rtn,:date from %WebStress.Scripts where ID = :id)
	set return=1
	if rtn'="" {
		set rtnDate=##class(%Library.Routine).GetDate(rtn_".obj")
		set rtnDate=$zdth(rtnDate,3)
		set rtnDate=rtnDate*86400+$piece(rtnDate,",",2)
		set return=$select(rtnDate=date:1,1:0)
	}
	quit return
}

Query ListByName() As %SQLQuery(CONTAINID = 1)
{
SELECT %ID,Name,RecordDateTime FROM Scripts
 ORDER BY Name
}

/// This callback method is invoked by the <METHOD>%Save</METHOD> method to 
/// provide notification that the object is being saved. It is called after 
/// the object's data has been successfully written to disk.
/// 
/// <P><VAR>insert</VAR> will be set to 1 if this object is being saved for the first time.
/// 
/// <P>If this method returns an error then the call to <METHOD>%Save</METHOD> will fail.
Method %OnAfterSave(insert As %Boolean) As %Status [ Private ]
{
	set CSPToken = 0
	set urlCount = ..URLs.Count()
	for url=1:1:urlCount {
		set urlObj = ..URLs.GetAt(url)
		set paramCount = urlObj.Parameters.Count()
		for param=1:1:paramCount {
			set paramObj = urlObj.Parameters.GetAt(param)
			if paramObj.Key="CSPToken" set CSPToken = 1 quit
		}
	}
	set id = ..%Id()
	&sql(update %WebStress.Scripts set ContainsCSPToken = :CSPToken where ID = :id)
	quit $$$OK
}

/// Used by debug to show what's going on
ClassMethod ShowProgress(msg)
{
	write !,$zdatetime($horolog,3),?25,msg
}

Storage Default
{
<Data name="ScriptsDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>DefaultPort</Value>
</Value>
<Value name="3">
<Value>DefaultServer</Value>
</Value>
<Value name="4">
<Value>ErrorCheck</Value>
</Value>
<Value name="5">
<Value>Name</Value>
</Value>
<Value name="6">
<Value>PostRunCode</Value>
</Value>
<Value name="7">
<Value>PreRunCode</Value>
</Value>
<Value name="8">
<Value>SavedDate</Value>
</Value>
<Value name="9">
<Value>SavedTime</Value>
</Value>
<Value name="10">
<Value>XDataTable</Value>
</Value>
<Value name="11">
<Value>LoopBackNumber</Value>
</Value>
<Value name="12">
<Value>LoopBackPercent</Value>
</Value>
<Value name="13">
<Value>SyncSave</Value>
</Value>
<Value name="14">
<Value>Version</Value>
</Value>
<Value name="15">
<Value>RecordMethod</Value>
</Value>
<Value name="16">
<Value>OriginalPort</Value>
</Value>
<Value name="17">
<Value>OriginalServer</Value>
</Value>
<Value name="18">
<Value>RandomisationGenTime</Value>
</Value>
<Value name="19">
<Value>RandomisationRoutine</Value>
</Value>
<Value name="20">
<Value>ContainsCSPToken</Value>
</Value>
<Value name="21">
<Value>RecordDateTime</Value>
</Value>
</Data>
<DataLocation>^WebStress.ScriptsD</DataLocation>
<DefaultData>ScriptsDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^WebStress.ScriptsD</IdLocation>
<IndexLocation>^WebStress.ScriptsI</IndexLocation>
<StreamLocation>^WebStress.ScriptsS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
