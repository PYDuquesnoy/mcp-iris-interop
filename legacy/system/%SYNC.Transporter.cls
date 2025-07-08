/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occDS, %syNLS)

/// <class>%SYNC.Transporter</class> is a utility class used to transport objects from one namespace to another.<br> <br>
/// <!doctype html public "-//w3c//dtd html 4.0 transitional//en">
/// <html>
/// <head>
///    <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
///    <meta name="GENERATOR" content="Mozilla/4.77 [en] (Windows NT 5.0; U) [Netscape]">
///    <title>SYNC Transporter</title>
/// </head>
/// <body>
/// <h1>SYNC Transporter</h1>
/// <h2>Overview</h2>
/// <p>
/// 	%SYNC.Transporter is a utility class used to export and import objects from one namespace to 
/// 	another. Raw object data is copied to a transport container global. The transport container global 
/// 		is then exported to a file and moved to the desired location where it can be imported 
/// 	into another namespace. The import namespace must contain runnable classes 
/// 	corresponding to type of each object contained in the transport container. 
/// 	IDs and references can be abstracted during transport and resolved on import to the correct ID value as it exists in the 
/// 	import namespace.
/// 	</p>
/// <h2>Create a Transport Container</h2>
/// 	<p>
/// 		To transport objects using the Transporter, simply instantiate the Transporter and add the desired objects. 
/// 		When all objects are in the transport container, export it to a file. The following method that transports instances
/// 		of Sample.Person to a transport container is implemented as:
/// <example>
/// classmethod TransportByState(pState as %String(MAXLEN=2) = "MA", pDirectory as %String = "") as %Status {
/// 	try {
/// 		set statement = ##class(%SQL.Statement).%New()
/// 		set statement.%ObjectSelectMode = 1
/// 		do statement.prepare("select %ID as ID from Sample.Person where home_state = ?")
/// 		set persons = statement.%Execute(pState)
/// 		set transporter = ##class(%SYNC.Transporter).%New()
/// 		while persons.%Next() { set tSC = transporter.AddObject(persons.ID.%Oid()) write !,$Select($$$ISOK(tSC):"Successfully added ",1:"Error occurred adding "),persons.ID.%Id()," ",persons.ID.Name," to the transporter" }
/// 		do transporter.ExportFile(pDirectory _ "people"_pState_".gof")
/// 		set tSC = $$$OK
/// 	}
/// 	catch tException {
/// 		set tSC = tException.AsStatus()
/// 	}
/// 	quit tSC
/// }
/// </example>
/// <br>
/// 	Running this method produces the following output:
/// <pre>
/// 		SAMPLES>d ##class(Sample.Person).TransportByState("NY","/Users/test/Downloads/")
/// 		
/// 		Successfully added 12 Nathanson,Debra I. to the transporter
/// 		Successfully added 19 North,Molly K. to the transporter
/// 		Successfully added 71 Grabscheid,Lawrence A. to the transporter
/// 		Successfully added 108 Massias,Mary I. to the transporter
/// 		Successfully added 179 Eastman,Lawrence M. to the transporter
/// 		Successfully added 188 Ihringer,Dmitry G. to the transporter
/// 		Successfully added 195 Isaacs,Dmitry A. to the transporter
/// 		Exporting to GO/GOF format started on 12/12/2011 08:31:33
/// 		Exporting global: ^OBJ.EXP.37
/// 		Export finished successfully.
/// 	</pre>
/// <br>
/// 		The file, peopleNY, created by running the example above now contains the object data for each of the objects selected 
/// 		by the dynamic SQL statement. The file also contains abstracted keys for each of the objects referenced 
/// 		by the objects explicitly added to the transport container. It is the user's responsiblity to explicitly 
/// 		add referenced objects if more than the key is required. For example, if the Company object referenced by 
/// 		an Employee object needs to transported then it must be added explicitly by calling AddObject and passing it 
/// 		the OID of the Company object.
/// </p>
/// <p>
/// 	The transport file can be moved to a place where it is visible to the namespace where it is to be imported. To import 
/// 	a transport file, simply instantiate the %SYNC.Transporter class and call the Import method. The following example simply imports 
/// the transport file back into the same namespace where it was produced. The rows transported are deleted first to demonstrate 
/// the Import behavior. 
/// <pre>
/// 		SAMPLES>d $system.SQL.Shell()
/// 		SQL Command Line Shell
/// 		----------------------------------------------------
/// 		
/// 		The command prefix is currently set to: <<nothing>>.
/// 		Enter q to quit, ? for help.
/// 		SAMPLES>>delete from Sample.Person where home_state = ?
/// 		2.	delete from Sample.Person where home_state = ?
/// 		
/// 		
/// 		Enter the value for parameter '1': NY
/// 		executing statement with parameter values: set %tResult=%tStatement.%Execute("NY")
/// 		7 Rows Affected
/// 		statement prepare time: 0.0157s, elapsed execute time: 0.0337s.
/// 		---------------------------------------------------------------------------
/// 		SAMPLES>>q
/// 		SAMPLES>set status = transporter.Import("/Users/danp/Downloads/peopleNY.gof",.count,.errors)
/// 		
/// 		SAMPLES>write status
/// 		1
/// 		SAMPLES>write count
/// 		7
/// 		SAMPLES>zw errors
/// 		errors=0
/// 		
/// 		SAMPLES>d $system.SQL.Shell()
/// 		SQL Command Line Shell
/// 		----------------------------------------------------
/// 		
/// 		The command prefix is currently set to: <<nothing>>.
/// 		Enter q to quit, ? for help.
/// 		SAMPLES>>select %id,name from sample.person where home_state = ?
/// 		1.	select %id,name from sample.person where home_state = ?
/// 		
/// 		Enter the value for parameter '1': NY
/// 		executing statement with parameter values: set %tResult=%tStatement.%Execute("NY")
/// 		ID	Name	
/// 		12	Nathanson,Debra I.
/// 		19	North,Molly K.
/// 		71	Grabscheid,Lawrence A.
/// 		108	Massias,Mary I.
/// 		179	Eastman,Lawrence M.
/// 		188	Ihringer,Dmitry G.
/// 		195	Isaacs,Dmitry A.
/// 		
/// 		7 Rows(s) Affected
/// 		statement prepare time: 0.0847s, elapsed execute time: 0.0012s.
/// 		---------------------------------------------------------------------------
/// 		SAMPLES>>
/// </pre>
/// <br>
/// </p>
/// 	<p>
/// 	After creating a transport container it is a good idea to delete the global used by calling 
/// 	<method>DeleteTransportGlobal</method>.
/// 	</p>
Class %SYNC.Transporter Extends %RegisteredObject [ System = 3 ]
{

/// transportGlobal is the name of the global that will contain transported objects.
Property transportGlobal As %String(MAXLEN = 250);

Property transporter As %String(MAXLEN = "") [ Internal, MultiDimensional ];

Property objectStack As %Integer [ Internal ];

/// This callback method is invoked by the <METHOD>%New</METHOD> method to 
/// provide notification that a new instance of an object is being created.
/// 
/// <P>If this method returns an error then the object will not be created.
/// 
/// This method initializes a new transporter global unless the user passes
/// the transporterId when instantiating this class. In that case, it is assumed
/// that the user wishes to add to an existing transporter global and the global
/// is not initialized if it exists.
Method %OnNew(initvalue As %RawString = "") As %Status [ Private, ProcedureBlock = 1 ]
{
	set tGlobalName =  "^OBJ.EXP."_$Select(initvalue'="":initvalue,1:$I(^OBJ.SYNCJOB))
	set ..transportGlobal = tGlobalName
		#; Only initialize the transport global if no initial value was provide
	if (initvalue = "") || ('$Data(@(tGlobalName))) {
		Kill @tGlobalName
		set @tGlobalName@("%%LOCALE")=$$$LOCALENAME
	}
	$$$createStack(..objectStack)
	Quit $$$OK
}

/// This method should be used to delete the transport global when it is no longer needed. The <var>pTransportId</var> 
/// is the integer appended to "^OBJ.EXP." to form the transport global name.
ClassMethod DeleteTransportGlobal(pTransportId As %RawString = "") As %Status [ ProcedureBlock = 1 ]
{
	if pTransportId '= "" {
		kill @("^OBJ.EXP."_pTransportId)
	}
	quit $$$OK
}

Method GlobalName() As %String [ CodeMode = expression, Internal ]
{
i%transportGlobal
}

/// Import is the method to call to import a transport container from a file. Each object contained in the transport container
/// is loaded into the current namespace. The number of objects found in the container and a log of all errors encountered during
/// import is returned to the caller.
Method Import(pFile As %String = "", ByRef pCount = 0, ByRef errorlog As %String = 0) As %Status
{
	new %objsync
	if $g(pFile) '= ""  {
		set tSC = ..loadTransportContainer(pFile)
		If $$$ISERR(tSC) Quit tSC
	}
	set %objsync = ..transportGlobal
	if ($g(@%objsync@("%%LOCALE"))'=$$$LOCALENAME){ s rc=$$$ERROR($$$SyncDiffLocales,$g(@%objsync@("%%LOCALE"))) }
	set tPtr = $Order(@%objsync@(0))
	while tPtr {
		set tOID = $Get(@%objsync@(tPtr,"i"))
			#; transported objects that have no serial value (OID) are meant to be skipped - they are literals.
			#; So far, we only have stream literals that are without identity.
		if tOID '= "" {
			set tClassname = $$$oidClassName(tOID)
			set tTransporter = ..getTransporter(tClassname,.tSC)
			if tTransporter '= "" {
				kill tUnresolved
				set pCount = pCount + 1
				set tOref = $$$CreateObject(tClassname) If tOref = $$$NULLOREF {set tSC = $$$ERROR($$$AbstractClassNotInstantiable,tClassname) }
				if $$$ISOK(tSC) { set tSC = tOref.%SyncTransport(tOID,tTransporter,%objsync,tPtr,##this,.tUnresolved) }
				if $$$ISERR(tSC) {
					if $Order(tUnresolved("")) {
							#; This indicates some unresolved references that are theoretically resolvable - requeue even if the object successfully imported
					}
					set errorlog(tPtr) = tSC, errorlog = errorlog + 1
				}
			}
			else { set errorlog(tPtr) = $$$ERROR($$$GeneralError,"Error generating transporter for "_$$$oidClassName(tOID)), errorlog = errorlog + 1 }
		}
		set tPtr = $Order(@%objsync@(tPtr))
	}
	quit $$$OK
}

/// loadTransportContainer is an internal method called by <method>Import</method> to import the transport container from
/// <var>pFile</var>. This method returns a <class>%Library.Status</class> value indicating success or failure.
Method loadTransportContainer(pFile As %String = "") As %Status [ Internal ]
{
	set %objsync = ..transportGlobal
	if pFile '= "" { set tSC = ##class(%Global).Import(,"",pFile,7,0,$extract(%objsync,2,*)) }
	else { set tSC = $$$ERROR($$$GeneralError,"No Transporter specified") }
	quit tSC
}

/// ExportFile will export the current transport container to the <var>pFile</var> file.
Method ExportFile(pFile As %String = "", qspec As %String = "") As %Status
{
	new %ROWID, %ROWCOUNT
	set tGlobal = ..transportGlobal
		#; Kill the resolved index as it has no value outside of a Transport destination
	kill @tGlobal@("r")
	set tSC = ##class(%Library.Global).Export(,..transportGlobal_".gbl",pFile,7,0,qspec)
	Quit tSC
}

/// <p>
/// AddObject adds the object whose OID is <var>pOID</var> to the transport container if that object 
/// is not already present in the container. Objects can be present in the container as either a complete
/// object or as a simple OID reference.
/// </p>
/// <p>
/// If <var>pDepth</var> is 0 (zero) and the object is not already present in the container then the complete object is added.
/// </p>
/// <p>
/// If <var>pDepth</var> is 1 (one) and the complete object is not already present in the container then the complete
/// object and the key of each object referenced by that object are added. 
/// </p>
Method AddObject(pOID As %ObjectIdentity = "", pDepth As %Integer = 1) As %Status
{
	set tSC = $$$OK
	try {
		set tClass = $$$oidClassName(pOID)
		if tClass '= "" {
			$$$clearStack(..objectStack)
			set tTransporter = ..getTransporter($$$oidClassName(pOID))
			if tTransporter '= "" { set tSC = $$export^@(tTransporter)(pOID,..transportGlobal,$Increment(@..transportGlobal),..objectStack,pDepth,##this) }
			else { throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"Error generating transporter for "_$$$oidClassName(tOID))) }
				#; Export the keys of the referenced objects
			while $$$STACK(..objectStack) {
				$$$popstack(..objectStack,tOID)
				set tTransporter = ..getTransporter($$$oidClassName(tOID))
				if tTransporter '= "" {
					set tSC = $$export^@(tTransporter)(tOID,..transportGlobal,,,0,##this)
					if $$$ISERR(tSC) { throw ##class(%Exception.StatusException).CreateFromStatus(tSC) }
				}
				else { throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"Error generating transporter for "_$$$oidClassName(tOID))) }
			}
		}
		else { set tSC = $$$ERROR($$$GeneralError,"Cannot determine class for OID = '"_$$$oidClassName(pOID)_"::"_$$$oidPrimary(pOID)_"'") }
	}
	catch tException {
		set tSC = tException.AsStatus()
	}
	quit tSC
}

/// Internal method to return the name of the routine that implements the transporter for <var>pClass</var>.
/// If the transporter is not yet generated for <var>pClass</var> then the generator is called. If no
/// transporter is found and the generator fails then NULL is returned.
Method getTransporter(pClass, ByRef pSC As %Library.Status) As %String [ Internal ]
{
	set pSC = $$$OK
	set tTransporter = $Get(..transporter(pClass))
	if tTransporter = "" {
		set tTransporter = $Get($$$EXTtransporter($$$pEXT,pClass))
		if tTransporter = "" {
			set tTransporter = $$Generate^%oueTransporter(pClass,.pSC)
			if tTransporter '= "" { set ..transporter(pClass) = tTransporter } else { throw }
		}
	}
	else { set ..transporter(pClass) = tTransporter }
	quit tTransporter
}

}
