/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occInclude

/// Whitelist facility to selectively restrict web access to [ZenMethod] 
/// calls.  The whitelist in question is namespace specific.  This allows
/// system administrators to configure the visibility of system level
/// calls based upon from whence the call originated. <p />
/// The whitelist is checked when a callback first attempts to call either
/// an instance or class method that has previously been compiled with a 
/// [ZenMethod] tag.  This check is only done when the request comes in 
/// from the client, purely internal invocations of the methods are not 
/// restricted.<p />
/// If whitelisting is enabled for the namespace, for a given method to be
/// called, it must be enabled in the whitelist.  Methods that are explicitly
/// disabled or simply not listed in the whitelist are rejected and an 
/// exception is thrown<p />
/// <b>How to Set-up and Enable Whitelisting:</b><p/>
/// The call <br/>
/// <code>Do ##class(%CSP.WhitelistUtils).%InitializeWhitelist()</code><br />
/// will scan the current namespace for all defined or inherited [ZenMethod]
/// functions.  Each function discovered will be added to the whitelist and 
/// enabled by default (this is done for backwards compatibility).  If a 
/// previous whitelist has been defined, this call will reinitialize it.  The
/// newly minted whitelist will not yet be active (and if whitelisting was 
/// previsously active, it will be turned off until the new list has been 
/// approved. <b>Note:</b> Depending on the size and complexity of the class 
/// dictionary in the current namespace, this method may take several seconds  
/// to complete<p />
/// The default initial list may be edited using the following two routines:<p />
/// <code>Do ##class(%CSP.WhitelistUtils).%EnableMethod(myClass,myMethod)</code><br />
/// <code>Do ##class(%CSP.WhitelistUtils).%DisableMethod(myClass,myMethod)</code><p />
/// The first adds or edits a given entry, approving it for general access.  The 
/// second explicitly bars web applications from calling the method in question.<p />
/// To approve the current whitelist for use and start enforcing the new policy, call:<br />
/// <code> Do ##class(%CSP.WhitelistUtils).%ActivateWhitelist()</code><p />
/// To temporarily disable whitelisting without reconfiguring the whitelist itself, call:<br />
/// <code> Do ##class(%CSP.WhitelistUtils).%DeactivateWhitelist()</code><p />
/// To see if whitelisting is active for the namespace, call:<br />
/// <code>Write ##class(%CSP.WhitelistUtils).%IsWhitelistEnabled()</code><p />
/// To query the individual entries of the whitelist, call:<br />
/// <code>Write ##class(%CSP.WhitelistUtils).%IsMethodEnabled(myClass,myMethod)</code><p />
/// Attempts to create, edit or change the activity status of the whitelist
/// require <b>Admin_Secure:USE</b> privilege.  Queries to inspect the whitelist or
/// its status are not so restricted.
Class %CSP.WhitelistUtils [ Abstract, Final, System = 3 ]
{

Parameter WHITELIST As STRING [ Final, Internal ] = "^ISCMethodWhitelist";

/// Search the named class for the methods matching the search criteria
/// Return an AET consisting of the name of the class searched (class)
/// and an array (methods) of all names of methods matching the criteria
/// or "" if no methods matching the criteria are found
ClassMethod SelectSearchNodes(className As %String, ref As %String, criteria As %DynamicObject) As %DynamicObject [ Internal ]
{
	//Constants defined in occKeyword.inc		
	Set result = {"class":(className), "super":"", "methods":[]}
	Set data=$data(@ref,value)
	If 'data Quit
	
 	Set sRef = "^oddDEF("""_className_""","""_$$$cCLASSsuper_""")"
	Set super = ""
	If ($data(@sRef,super)) {
		Set result.super = super
	}
	
 	Set mRef = "^oddDEF("""_className_""","""_$$$cCLASSmethod_""")"
	Set value=""
	Set key=""
	Set key=$Order(@mRef@(key),1,value) 
	While (key'="") {
		Set Maybe = 0
 		Set detailRef = "^oddDEF("""_className_""",""m"","""_key_""")"
		Set detailKey = ""
		Set detailKey = $Order(@detailRef@(detailKey),1,detailValue)
		While (detailKey'="") {	
 			If (detailKey=$$$cMETHclassmethod)&&(criteria.%Get("ClassMethod")) {
	 			Set Maybe=Maybe+1
 			}
 			ElseIf (detailKey=$$$cMETHzenmethod)&&(criteria.%Get("ZENMethod")) {
	 			Set Maybe= Maybe+1
 			}			
			Set detailKey = $Order(@detailRef@(detailKey),1,detailValue)
		}
		If (Maybe = criteria.%Size()) {
			Do result.methods.%Push(key)
		}
		Set key=$Order(@mRef@(key),1,value) 
	}
	If (result.methods.%Size()=0) Set result=""
	Quit result
}

/// Get an array of matching classname hits based on a search pattern,
/// a classname pattern, and assorted flags
ClassMethod SelectTargetClasses(PatternList As %String = "*.cls", System As %Boolean = 0, Max As %Integer = 20000) As %DynamicArray [ Internal ]
{
	Set result = []
 	Set found=0
	Set attrs=""
	If System Set attrs=attrs_","_$$$GetSimpleMessage("%Compiler","SearchSystem")
	Set sc=##class(%RoutineMgr).StudioOpenDialogExecute(.QHandle,PatternList,1,1,System,1,,,)
	If $$$ISERR(sc) Quit sc
	Set idx=$list(QHandle)
	Set item=$order(^||%RoutineList(idx,1,""),1,data)
	While item'=""&&(found<Max) {
		Set name=$piece($list(data),".",1,*-1)
  		If (name'="")&&($data(^oddDEF(name))) {
		 	Set sRef = "^oddDEF("""_name_""","""_$$$cCLASSsuper_""")"
			Set sArr = []
			Set super = ""
			If ($data(@sRef,super)) {
				Set nSuper = $Length(super,",")
				Set sIdx = 1
				While (sIdx<=nSuper) {
					Set sClass = $Piece(super,",",sIdx)
					Set sIdx = sIdx+1
					If (sClass'="") {
						If (($Length(sClass,".")=1)&&($Find(sClass,"%")'=2)) { // need to prefix
							Set pkg = ""
							Set pLen = $Length(name,".")
							Set pIdx = 1
							While (pIdx<pLen) {
								Set pkg = pkg_$Piece(name,".",pIdx)_"."
								Set pIdx = pIdx+1
							}
							Set sClass = pkg_sClass
						}
						If ('((sClass="%RegisteredObject")||(sClass="%Persistent"))) {
							Do sArr.%Push(sClass)
						}
					}
				}
			}
 		 	Do result.%Push({"class":(name),"super":(sArr),"ref":("^oddDEF("""_name_""")")})
			Set found = found+1
		}
		
		Set item=$order(^||%RoutineList(idx,1,item),1,data)
	}
	Kill ^||%RoutineList(idx)
	Quit result
}

/// Build an object, organized by classname, for all the ZenMethods 
/// found in the current namespace.  
ClassMethod IdentifyZenMethods(aet) As %DynamicObject [ Internal ]
{
	Set results = ##class(%DynamicObject).%New()
	
	Set all = ..SelectTargetClasses("*.cls",1)
	Set itr = all.%GetIterator()
	While (itr.%GetNext(.idx,.rec)) {
		Set node = ..SelectSearchNodes(rec.class,rec.ref,{"ZENMethod":true})
		If (node'="") {
			Set detail = {"super":(node.super),"methods":(node.methods)}
			Do results.%Set(node.class,detail)
		}
	}
	Set safety=4096
	Set promoted=1
	While ((promoted>0)&&(safety>0)) {
		Set promoted = 0
		Set safety = safety - 1
		Set all = ..SelectTargetClasses("*.cls",1)
		Set itr = all.%GetIterator()
		While (itr.%GetNext(.idx,.rec)) {
			If ((rec.class'="") && (results.%Get(rec.class)="")) { // not in the set
				Set super = rec.super
				Set sItr = super.%GetIterator()
				While (sItr.%GetNext(.sIdx,.sClass)) {
					If (results.%Get(sClass)'="") { // promote
						Set promoted = promoted +1
						Set detail = {"super":(sClass),"methods":[]}
						Do results.%Set(rec.class,detail)
					}
				}
			}
			Else {
				Set rec.class = "" //skip this in future
			}
		}
	}
	
	Set safety=4096
	Set deferred = 1
	While ((deferred>0)&&(safety>0)) {
		Set safety = safety -1
		Set deferred = 0
		Set itr = results.%GetIterator()
		While (itr.%GetNext(.cls,.detail)) {
			Set super = detail.%Get("super")
			If (super'="") {
				Set superNode = results.%Get(super) 
				If (superNode="") { // no entry for superclass
					Do detail.%Set("super","")
				}
				Else {
					If (superNode.%Get(super)="") { // safe to add points from supernode
						Set mItr = superNode.methods.%GetIterator()
						While (mItr.%GetNext(.mIdx,.method)) {
							Do detail.methods.%Push(method)
						}
						Do detail.%Set("super","")
					}
					Else {
						Set deferred = deferred +1
					}
				}
			}		
		}
	}

 	Quit results
}

ClassMethod CommitWhitelist(aet As %DynamicArray) [ Internal ]
{
	Kill @..#WHITELIST
	Set aItr = aet.%GetIterator()
	While (aItr.%GetNext(.aKey,.node)) {
		Set cls = aKey
 		Set mItr = node.methods.%GetIterator()
		While (mItr.%GetNext(.mIdx,.method)) {
			Set ref = ..#WHITELIST_"("""_cls_""","""_method_""")"
			Set @ref = 1
		}
	}
	// Newly created whitelists are off by default
	Set ref = ..#WHITELIST
	Set @ref = 0
 	Quit
}

/// Validate that the user has appropriate access.
ClassMethod CheckSecurity() As %Boolean [ Internal ]
{
	// test if user has resources
	If ('$System.Security.Check("%Admin_Secure","USE")) {
		Throw ##class(%Exception.StatusException).CreateFromStatus(940)
	}
	Quit 1
}

/// This method identifies (and tags as approved) all methods tagged as 
/// ZenMethod callbacks in the current namespace.  This data is used to 
/// build the initial whitelist.  This list may then be edited (using the 
/// methods found here) as needed.  This call does <b>NOT</b> activate the
/// use of the whitelist.  That is done by a separate call 
/// (%ActivateWhitelist) once the whitelist has been configured to the 
/// site administrators' satisfaction.<br />
/// If a previous version of the whitelist was in place, this call will 
/// overwrite its settings in favor of a fresh scan and will mark the list
/// as inactive pending approval.
ClassMethod %InitializeWhitelist() As %Status
{
	If (..CheckSecurity()) {
		Set rs = ..IdentifyZenMethods(0)
		Do ..CommitWhitelist(rs)
	}
	Quit $$$OK
}

/// Turn on the use of the whitelist for the current namespace.
/// When activated, all web callbacks to zenMethods will be tested against
/// the whitelist.  Any method that is either missing or set to false (0) 
/// will be disallowed.  Methods set to true (1) in the whitelist will be 
/// allowed to execute according to normal role and privilege restrictions.
ClassMethod %ActivateWhitelist() As %Status
{
	If (..CheckSecurity()) {
		Set ref = ..#WHITELIST
		Set @ref = 1
	}
	Quit $$$OK
}

/// Turn off (but do not otherwise alter) the use of the whitelist for 
/// the current namespace.  When deactivated, all web callbacks to 
/// zenMethods will be permitted according to normal role and privilege
/// restrictions.
ClassMethod %DeactivateWhitelist() As %Status
{
	If (..CheckSecurity()) {
		Set ref = ..#WHITELIST
		Set @ref = 0
	}
	Quit $$$OK
}

/// Tag a given member of the whitelist as false (meaning do not execute).
/// The entry remains in the whitelist.
ClassMethod %DisableMethod(pClass As %String, pMethod As %String) As %Status
{
	If (..CheckSecurity()) {
		Set ref = ..#WHITELIST_"("""_pClass_""","""_pMethod_""")"
		Set @ref = 0
	}
	Quit $$$OK
}

/// Tag a given member of the whitelist as true (meaning ok to execute).
/// When the whitelist is active, a method must both appear in the whitelist
/// and be set to true in order for the method to be called from a web 
/// access point.
ClassMethod %EnableMethod(pClass As %String, pMethod As %String) As %Status
{
	If (..CheckSecurity()) {
		Set ref = ..#WHITELIST_"("""_pClass_""","""_pMethod_""")"
		Set @ref = 1
	}
	Quit $$$OK
}

/// Test to see if whitelist checking is enabled for this namespace
ClassMethod %IsWhitelistEnabled() As %Boolean
{
	Try {
		Set result = ##class(%SYS.WhitelistUtils).IsWhitelistEnabled()
	}
	Catch ex {
		Set result = 1
	}
	Quit result
}

/// Test to see if the given method call should be allowed under the 
/// current whitelist policy 
ClassMethod %IsMethodEnabled(pClass As %String, pMethod As %String) As %Boolean
{
	Try {
		Set result = ##class(%SYS.WhitelistUtils).IsMethodEnabled(pClass,pMethod)
	}
	Catch ex {
		Set result = 0 // Assume the worst
	}
	Quit result
}

}
