/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>Lister implementation for scanning a filesystem.</p>
/// 
/// <p><b>Lister Parameters</b> to be supplied to <method>AddListToBatch</method> and
/// 	<method>ProcessList</method> calls:</p>
/// <ol>
///     <li><b>path</b> As <class>%String</class> - the directory where to look for files</li>
///     <li><b>extensions</b> As <class>%List</class> - the extensions (without leading dot) to load</li>
///     <li><b>recursive</b> As <class>%Boolean</class> - whether or not to recurse into subdirectories</li>
///     <li><b>filter</b> As <class>%String</class> - a code fragment that can be called through $xecute to 
/// 			evaluate a filename and directory. For example: <blockquote><pre>"(fn,dir) quit '$find(fn,""draft"")"</pre></blockquote></li>
/// </ol>
/// 
/// <p><b>External ID structure:</b> [GroupName][LocalRef]</p>
/// 	<ul>
/// 		<li>GroupName = full path to the directory containing the file</li>
///     <li>LocalRef = file name, including extension</li>
/// </ul>
/// 
/// <p><b>Lister alias:</b> "FILE"</p>
/// <p><b>Default Processor:</b> <class>%iKnow.Source.File.Processor</class></p>
Class %iKnow.Source.File.Lister Extends %iKnow.Source.Lister [ Deprecated, System = 4 ]
{

Property PathSeparator As %String [ Private ];

Method %OnNew(domId As %Integer) As %Status [ Private, ServerOnly = 1 ]
{
    Set i%PathSeparator=$s($$$isWINDOWS:"\",$$$isUNIX:"/",$$$isVMS:"")
    Quit ##super(domId)
}

/// <p>Scans through the directory as dictated by the Lister Parameters. 
/// No metadata is gathered along the way.</p>
/// <p>See also <method class="%iKnow.Source.Lister">ExpandList</method> in <class>%iKnow.Source.Lister</class>.</p>
Method ExpandList(listparams As %List) As %Status
{
    Set path=$lg(listparams)
    Set extensions=$lg(listparams,2)
    $$$IKENSURELISTSTR(extensions)
    Set recursive=$lg(listparams,3)
    Set filter=$lg(listparams,4)
    Set sep=i%PathSeparator

    // First, see if it is a directory, or file name
    Set basedir=$zu(12,path,2)   // Canonicalize as directory ("" if not directory)
    If basedir="" {
        Set path=$zu(12,path,0)  // Canonicalize path as a file or directory
        // Find last path separator (this will need to be done differently for VMS!)
        Set len=$l(path,sep)
        Set ref=$lb(i%ListerClassId,..AddGroup($p(path,sep,1,len-1)_sep),$p(path,sep,len))
        Set sc=..StoreRef(ref)
        Do:$$$ISERR(sc) ..ReportError(ref,sc)
        Quit sc
    }

    Kill ^||%IK.SubDirs
    Set ^||%IK.SubDirs=1,^||%IK.SubDirs(1)=basedir

    For i=1:1 {
        Set basedir=$g(^||%IK.SubDirs(i))
        Quit:basedir=""
        Set subdirId=0

        Set path=$zsearch(basedir_"*")
        While path'="" {
            Set fn=$e(path,$l(basedir)+1,*)     // Isolate filename
            // skip . and .. directories (note: this is not valid for VMS!)
            If fn'=".",fn'=".." {
                Set xpath=$zutil(12,path,2)     // Canonicalize subdir as a directory an verify if it exists
                If xpath="" {
                    If extensions'="" {
                        Set len=$l(fn,".")
                        If len>1,'$LF(extensions,$p(fn,".",len)) { Goto nxt }
                    }
                    If filter'="",'$xecute(filter,fn,basedir) { Goto nxt }
                    Set:'subdirId subdirId=..AddGroup(basedir)
		    // Build ref with canonicized filename
                    Set ref=$lb(i%ListerClassId,subdirId,$e($zu(12,path),$l(basedir)+1,*))
                    Set sc=..StoreRef(ref)
                    Do:$$$ISERR(sc) ..ReportError(ref,sc)
                } ElseIf recursive {
                    Set ^||%IK.SubDirs($i(^||%IK.SubDirs))=xpath    // Save if it's valid directory
                }
            }
nxt         Set path=$zsearch("")
        }
    }
    Kill ^||%IK.SubDirs
    Quit $$$OK
}

/// <p>Splits the Full Reference into a Group Name and Local Reference based on their path.</p>
/// <p>See also <method class="%iKnow.Source.Lister">SplitFullRef</method> in <class>%iKnow.Source.Lister</class>.</p>
ClassMethod SplitFullRef(domainId As %Integer, fullRef As %String, Output groupName As %String, Output localRef As %String) As %Status [ Private ]
{
    Set sep=$s($$$isWINDOWS:"\",$$$isUNIX:"/",$$$isVMS:"")
    Set len=$l(fullRef,sep)
    Set groupName=$zu(12,$p(fullRef,sep,1,len-1),0)_sep
    Set localRef=$p(fullRef,sep,len)
    Set localRef=$p($zu(12,groupName_localRef,0),groupName,2)
    Quit $$$OK
}

/// <p>Appends the file name (local reference) directly to the directory (group name) to form the Full Reference.</p>
/// <p>See also <method class="%iKnow.Source.Lister">BuildFullRef</method> in <class>%iKnow.Source.Lister</class>.</p>
ClassMethod BuildFullRef(domainId As %Integer, groupName As %String, localRef As %String) As %String [ Private ]
{
 Quit groupName _ localRef
}

/// <p>Lister alias: "FILE"</p>
ClassMethod GetAlias() As %String
{
 Quit "FILE"
}

ClassMethod FormatParams(listerParams As %List) As %String
{
 Quit "path:" _ $lg(listerParams) _ ";extensions:[" _ $lts($lg(listerParams,2)) _ "];recursive:" _ $lg(listerParams,3) _ ";filter:" _ $lg(listerParams,4)
}

/// <p>Tests performed by this Lister:</p>
/// <ol>
/// 		<li>path: checks whether this is a valid string (no check on whether this is a valid path!)</li>
/// 		<li>extensions: no checks</li>
/// 		<li>recursive: no checks</li>
/// 		<li>filter: if nonempty, checks whether this is a valid expression for $xecute() with two parameters</li>
/// </ol>
Method TestParams(listerParams...) As %Status
{
    Set path=$g(listerParams(1))
    quit:(path="") $$$ERROR($$$IKMissingListerParam, 1, "path")
    // we do not check whether a path exists!
    
    Set extensions=$g(listerParams(2))
    Set recursive=$g(listerParams(3))
    
    Set filter=$g(listerParams(4))
    if (filter'="") {
	    set tSC = $$$OK
	    try {
		    set x = $xecute(filter,"filename","basedir")
	    } catch (ex) {
		    set tSC = ex.AsStatus()
		    set tSC = $$$ERROR($$$IKListerParamError, 4, "filter", "Error in filter expression: "_$$GetErrorText^%apiOBJ(tSC))
	    }
	    quit:$$$ISERR(tSC) tSC
    }
    
	quit $$$OK
}

/// Builds a reference for use in $$$IKPSIMPLEEXTIDS domains. For File Listers, this
/// defaults to the FULL reference rather than just the Local Ref (overall default)
ClassMethod BuildSimpleRefFromComposite(domainId As %Integer, ref As %List, Output sc As %Status = {$$$OK}) As %String [ Internal ]
{
	quit ..BuildFullRefFromComposite(domainId, ref, .sc)
}

}
