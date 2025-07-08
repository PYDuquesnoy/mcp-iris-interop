/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// FOR INTERNAL USE - do not invoke directly
Class %XDBC.Gateway.ParameterMetaData Extends %RegisteredObject [ System = 4 ]
{

Parameter PARAMETERMODEUNKNOWN As Integer = 0;

Parameter PARAMETERMODEIN As Integer = 1;

Parameter PARAMETERMODEINOUT As Integer = 2;

Parameter PARAMETERMODEOUT As Integer = 4;

Property %metadata As %List [ Internal, MultiDimensional, Private ];

Method %OnNew(metadata As %List) As %Status
{
    /*
        mdl.add(metadata.getParameterMode(paramIndex));
        mdl.add(metadata.getParameterType(paramIndex));
        mdl.add(metadata.getPrecision(paramIndex));
        mdl.add(metadata.getScale(paramIndex));
        mdl.add(metadata.isNullable(paramIndex));
        mdl.add(metadata.getParameterTypeName(paramIndex));
    */
    set ..%metadata = $listget(metadata)
    set cstart = 2
    for c = 1:1:..%metadata {
        set ..%metadata(c) = $list(metadata,cstart, cstart + 5)
        set cstart = cstart + 6
    }
    return $$$OK
}

Method GetParameterCount() As %Integer
{
    return ..%metadata
}

Method IsNullable(param As %Integer) As %String(MAXLEN=220)
{
    return $listget(..%metadata(param), 5)
}

Method GetPrecision(param As %Integer) As %Integer
{
    return $listget(..%metadata(param), 3)
}

Method GetScale(param As %Integer) As %Integer
{
    return $listget(..%metadata(param), 4)
}

Method GetParameterType(param As %Integer) As %Integer
{
    return $listget(..%metadata(param), 2)
}

Method GetParameterTypeName(param As %Integer) As %String(MAXLEN=220)
{
    return $listget(..%metadata(param), 6)
}

Method GetParameterMode(param As %Integer) As %String(MAXLEN=220)
{
    return $listget(..%metadata(param), 1)
}

}
