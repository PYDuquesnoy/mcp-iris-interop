/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Api.InteropEditors.OnGeneration Extends %Projection.AbstractProjection
{

/// This method is invoked when a class is compiled
ClassMethod CreateProjection(cls As %String, ByRef params) As %Status
{
    // Get the UrlMap from the generated dispatch class
    set dispatchClass=$Piece(cls, ".", 1,*-1)_".disp"
    set tXDataID=dispatchClass_"||UrlMap"
    quit:'##class(%Dictionary.XDataDefinition).%ExistsId(tXDataID) $$$ERROR($$$GeneralError, "XData block "_tXDataID_" is undefined")
    set urlMap=##class(%Dictionary.XDataDefinition).%OpenId(dispatchClass_"||UrlMap")
    do urlMap.Data.Rewind()

    // Create a temporary url map to store original data
    set tUrlMap=##class("%Stream.TmpCharacter").%New()
    do tUrlMap.CopyFrom(urlMap.Data)
    do tUrlMap.Rewind()

    // Overwrite the url map, replacing plugin path parameter with a regex
    set tEndPos = 1
    set tStartPos = tUrlMap.FindAt(tEndPos, ":pluginPath") - 1
    do tUrlMap.MoveTo(tEndPos)
    while (tStartPos > 0) {
        set len = tStartPos - tEndPos + 1
        do urlMap.Data.Write(tUrlMap.Read(.len, .sc))
        return:$$$ISERR(sc) sc
        do urlMap.Data.Write("((?s).+)")
        set tEndPos = tStartPos + $Length(":pluginPath") + 1
        set tStartPos = tUrlMap.FindAt(tEndPos, ":pluginPath") - 1
        do tUrlMap.MoveTo(tEndPos)
    }
    do urlMap.Data.MoveToEnd()
    do urlMap.Data.Write(tUrlMap.Read(, .sc))
    do urlMap.%Save()
    quit sc
}

}
