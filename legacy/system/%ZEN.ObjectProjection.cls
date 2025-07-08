/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Projection class used by <class>%ZEN.Component.object</class> classes.
/// This is used to manage post-compilation actions for Zen components.
Class %ZEN.ObjectProjection Extends %Projection.AbstractProjection [ Deprecated, System = 3 ]
{

/// Add the Zen class, <var>pClass</var> to the post-compilation queue.
/// <var>pFlag</var> is a csv-list indicating what kind of post-compile action are needed:<br>
/// "schema" - XML schema for Studio needs to be regenerated.<br>
/// "HTML" - HTML include files (CSS and js) need to be regenerated.<br>
/// "SVG" - SVG include files (CSS and js) need to be regenerated.<br>
ClassMethod %QueueClass(pClass As %String, pFlag As %String) As %Status
{
	Set tSC = $$$OK

	#; add class to post-compile queue(s)
	For n = 1:1:$L(pFlag,",") {
		Set tFlag = $P(pFlag,",",n)
		Set:tFlag'="" ^IRIS.Temp.ZENQueue(%ISCName,pClass,tFlag) = ""
	}
	Quit tSC
}

/// Execute the various post-compilation actions for the Zen library.
ClassMethod EndCompile(qstruct) As %Status
{
	Set tSC = $$$OK
	Set $ZTRAP = "Trap"
	Do {
		Set tSchema = 0

		#; assemble list of work to do
		Set tClass = $O(^IRIS.Temp.ZENQueue(%ISCName,""))
		While (tClass '= "") {
			Set tPkg = $P(tClass,".",1,$L(tClass,".")-1)
	
			#; find modules this class belongs to (by package)
			Do $zobjclassmethod(tClass,"%GetIncludeInfo",.tModules)

			Set tFlag = $O(^IRIS.Temp.ZENQueue(%ISCName,tClass,""))
			While (tFlag '= "") {
				If (tFlag = "schema") {
					Set tSchema = 1
				}
				If ((tFlag = "HTML")||(tFlag = "SVG")) {
					Set tPackages(tPkg) = ""
				}
				Set tFlag = $O(^IRIS.Temp.ZENQueue(%ISCName,tClass,tFlag))
			}
			Set tClass = $O(^IRIS.Temp.ZENQueue(%ISCName,tClass))
		}
	
		#; clear queue	
		Kill ^IRIS.Temp.ZENQueue(%ISCName)

		#; perform actions

		#; include files
		Set tDisplay=$$$qualifierGetValue(qstruct,"displaylog")
		Set queue=$system.WorkMgr.%New()
		Set tKey = $O(tPackages(""))
		While (tKey '= "") {
			Set tSC=queue.Queue("##class(%ZEN.ObjectProjection).CreateIncludes",tKey,.tModules,tDisplay) If $$$ISERR(tSC) QUIT
			Set tKey = $O(tPackages(tKey))
		}
		If $$$ISERR(tSC) Quit
		Set tSC=queue.Sync()
		If $$$ISERR(tSC) Quit

		#; schemas
		If (tSchema) {
			Set tSC = ##class(%ZEN.Utils).%InvalidateSchema()
			If $$$ISERR(tSC) Quit
		}

	} While(0)
Exit
	Quit tSC
Trap
 	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

ClassMethod CreateIncludes(pKey As %String, ByRef pModules As %String, pDisplay As %Boolean = 1) As %Status
{
	$$$SuspendErrorCount
	Quit ##class(%ZEN.Utils).%GenerateIncludeFilesForModules(pKey,.pModules,,pDisplay)
}

/// This is called when a component class is compiled.
ClassMethod CreateProjection(pClassName As %String, ByRef parameters As %String, modified As %String) As %Status
{
 	Set $ZT="Trap",tSC=$$$OK
	Do {
		Set tActions = $parameter(pClassName,"POSTCOMPILEACTIONS")
		If (tActions '= "") {
			Set tSC = ..%QueueClass(pClassName,tActions)
			If $$$ISERR(tSC) Quit
		}
	} While (0)
Exit
	Quit tSC
Trap
 	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// This is called when a component class is removed.
ClassMethod RemoveProjection(pClassName As %String, ByRef parameters As %String, recompile As %Boolean) As %Status
{
 	Set $ZT="Trap",tSC=$$$OK
	Do {
		#; it would be nice to delete the associated include files for this
		#; class, but that is hard to do with no class to call!

	} While(0)
Exit
  	Quit tSC
Trap
 	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

}
