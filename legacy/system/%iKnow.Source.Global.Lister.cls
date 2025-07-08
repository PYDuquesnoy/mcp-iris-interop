/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>Lister implementation for retrieving sources directly from globals.</p>
/// 
/// <p><b>Lister Parameters</b> to be supplied to <method>AddListToBatch</method> and
/// 	<method>ProcessList</method> calls:</p>
/// <ol>
///     <li><b>globalref</b> As <class>%String</class> - global reference where data is stored</li>
///     <li><b>begsub</b> As <class>%String</class> - beginning subscript (if not "")</li>
///     <li><b>endsub</b> As <class>%String</class> - ending subscript (default "")</li>
///     <li><b>filter</b> As <class>%String</class> - default "", $xecute expression, passed current subscript
///         returns non-zero if this location needs to be processed</li>
/// </ol>
/// 
/// <p><b>External ID structure:</b> [GroupName]:[LocalRef]</p>
/// 	<ul>
/// 		<li>GroupName = globalref passed to lister</li>
///     <li>LocalRef = final subscript</li>
/// </ul>
/// 
/// <p><b>Lister alias:</b> "GLOBAL"</p>
/// <p><b>Default Processor:</b> <class>%iKnow.Source.Global.Processor</class></p>
Class %iKnow.Source.Global.Lister Extends %iKnow.Source.Lister [ Deprecated, System = 4 ]
{

/// <p>Scans through the global nodes as dictated by the Lister Parameters. 
/// No metadata is gathered along the way.</p>
/// <p>See also ExpandList in <class>%iKnow.Source.Lister</class>.</p>
Method ExpandList(listparams As %List) As %Status
{
    Set globalref=$lg(listparams)
    Set nam=$lg(listparams,2)
    Set endsub=$lg(listparams,3)
    Set filter=$lg(listparams,4)
    Set grpid=0

    // First check if beginning subscript exists (if not "")
    If nam'="",$d(@globalref@(nam)),filter=""||$xecute(filter,nam) {
        Set grpid=..AddGroup(globalref)
	Set ref=$lb(i%ListerClassId,grpid,nam)
	Set sc=..StoreRef(ref)
	Do:$$$ISERR(sc) ..ReportError(ref,sc)
    }
    For {
	Set nam=$o(@globalref@(nam))
	Quit:nam=""
	If endsub'="",nam]]endsub { Quit }
	If filter=""||$xecute(filter,nam) {
	    Set:'grpid grpid=..AddGroup(globalref)
	    Set ref=$lb(i%ListerClassId,grpid,nam)
	    Set sc=..StoreRef(ref)
	    Do:$$$ISERR(sc) ..ReportError(ref,sc)
	}
    }
    Quit $$$OK
}

/// <p>Lister alias: "GLOBAL"</p>
ClassMethod GetAlias() As %String
{
    Quit "GLOBAL"
}

/// <p>Splits the full reference in group name and local reference.
/// The group name is the global reference, and the local reference is the final subscript.</p>
/// <p>See also <method class="%iKnow.Source.Lister">SplitFullRef</method> in <class>%iKnow.Source.Lister</class>.</p>
ClassMethod SplitFullRef(domainId As %Integer, fullRef As %String, Output groupName As %String, Output localRef As %String) As %Status [ Private ]
{
    Set len=$ql(fullRef),localRef=$qs(fullRef,len)
    Set groupName=$p(fullRef,"(")
    For i=1:1:len-1 { Set groupName=$na(@groupName@($qs(fullRef,i))) }
    Quit $$$OK
}

/// <p>Builds the full reference making a global reference with $NAME.</p>
/// <p>See also <method class="%iKnow.Source.Lister">BuildFullRef</method> in <class>%iKnow.Source.Lister</class>.</p>
ClassMethod BuildFullRef(domainId As %Integer, groupName As %String, localRef As %String) As %String [ Private ]
{
 Quit $name(@groupName@(localRef))
}

/// <p>Tests performed by this Lister:</p>
/// <ol>
/// 		<li>globalref: checks whether a vald global ref (but does not check global existence)</li>
/// 		<li>begsub: no checks</li>
/// 		<li>endsub: no checks</li>
/// 		<li>filter: if nonempty, checks whether this is a valid expression for $xecute() with two parameters</li>
/// </ol>
Method TestParams(listerParams...) As %Status
{
    Set globalref=$g(listerParams(1))
    quit:(globalref="") $$$ERROR($$$IKMissingListerParam, 1, "globalref")
    
    // check if this is a valid global reference
    // BDB300: subscripts and namespace references are allowed
    if $e(globalref,1)'="^" {
	    quit $$$ERROR($$$IKListerParamError, 1, "globalref", $system.Status.GetErrorText($$$ERROR($$$InvalidGlobalName, $e(globalref,2,*))))
    } else { 
    	set tSC = $$$OK
    	try {
	    	set x = $order(@globalref@(""))
    	} catch (ex) {
	    	// syntax or subscript errors mean the globalref was illegal
	    	set tSC = $$$ERROR($$$IKListerParamError, 1, "globalref", $system.Status.GetErrorText($$$ERROR($$$InvalidGlobalName, $e(globalref,2,*))))
    	}
    	quit:$$$ISERR(tSC) tSC
    }
    
    Set begsub=$g(listerParams(2))
    Set endsub=$g(listerParams(3))
    
    Set filter=$g(listerParams(4))
    if (filter'="") {
	    set tSC = $$$OK
	    try {
		    set x = $xecute(filter,"subscript")
	    } catch (ex) {
		    set tSC = ex.AsStatus()
		    set tSC = $$$ERROR($$$IKListerParamError, 4, "filter", "Error in filter expression: "_$$GetErrorText^%apiOBJ(tSC))
	    }
	    quit:$$$ISERR(tSC) tSC
    }
    
	quit $$$OK
}

}
