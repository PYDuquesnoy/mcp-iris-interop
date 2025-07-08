/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This Processor implementation reads data from a filesystem, as listed by the ExpandList
/// method of the <class>%iKnow.Source.File.Lister</class>.</p>
/// 
/// <p><b>Processor parameters:</b></p>
/// <ol>
///     <li><b>encoding</b> As <class>%String</class> - encoding of the files to be read.</li>
/// </ol>
/// 
/// <p><b>Extracted metadata keys:</b></p>
/// <ol>
///     <li>Size</li>
///     <li>DateCreated</li>
///     <li>DateModified</li>
/// </ol>
Class %iKnow.Source.File.Processor Extends %iKnow.Source.Processor [ Deprecated, System = 4 ]
{

Property OpenParms As %String [ InitialExpression = "RU", Private ];

Property Directory As %String [ Private ];

Property DirectoryId As %Integer [ Private ];

Method SetParams(params As %String) As %Status
{
    If params'=i%Params {
        Set encoding=$lg(params)
        If encoding'="" {
            // Translate the encoding to the logical name
            Set enc=##class(%SYS.NLS.Table).DisplayToLogical(encoding)
            // If the logical name was specified, we take that one
            Set:enc="" enc=##class(%SYS.NLS.Table).LogicalToDisplay(encoding)
            Set:enc'="" enc="K\"_enc_"\"
        } Else {
            Set enc=""
        }
        Set i%OpenParms="RU"_enc
        Set i%Params=params
    }
    Quit $$$OK
}

ClassMethod GetMetadataKeys(params As %String) As %List
{
    Quit $LB("Size","DateCreated","DateModified")
}

Method FetchSource(loc As %Integer, ref As %List) As %Status [ Private ]
{
    Set sc=$$$OK
    // Unpack reference into filename
    Set groupId=$lg(ref,2)
    Set:groupId'=i%DirectoryId i%DirectoryId=groupId,i%Directory=##class(%iKnow.Source.Lister).GetGroupName(i%DomainId,$lg(ref),groupId)
    Set ref=i%Directory_$lg(ref,3)
    Try {
        Open ref:i%OpenParms:10 If '$T { Set sc=$$$ERROR($$$IKFileOpenFailed, ref) }
    } Catch {
        Set sc=$$$ERROR($$$IKCaughtError,..%ClassName(1)_":FetchSource",$ze)
    }
    Quit:$$$ISERR(sc) sc

    // Pick up metadata, save for now in i%MetaData
    set tSC = ..SetCurrentMetadataValues($lb($zu(140,1,ref),$zu(140,2,ref),$zu(140,3,ref)))

    Set tIO=$IO
    Try {
        Set tEOFMode=$ZU(68,40) Do $ZU(68,40,1)
        Use ref
        Do {
            Read line#32766:0
            Set atend=$ZEOF||($T&&($l(line)<32766))
            Set:line'="" sc=i%Buffer.BufferString(.line)
            Quit:$$$ISERR(sc)
        } While 'atend
    } Catch {
        Set sc=$$$ERROR($$$IKCaughtError,..%ClassName(1)_":FetchSource",$ze)
    }
    Do $ZU(68,40,tEOFMode)
    Use tIO
    Close ref
    Quit sc
}

}
