/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %syGluedef

/// This class holds an array of "lazy" Atelier objects
Class %Atelier.v1.Utils.LazyCollection Extends %RegisteredObject
{

Property DocArray [ MultiDimensional ];

Method %OnNew(ByRef pArray) As %Status
{
    Merge ..DocArray=pArray
    Quit $$$OK
}

Method %ToJSON(Output outstr) As %String
{
    #dim tName As %String
    #dim tFirst As %Integer
    #dim tObj
    
    #; We won't support returning a value
    If $Quit Do $$$GLUERROR($$$ERUNIMP)
    
    If $Data(outstr) {
        Do outstr.Write("{""content"":[")
    } Else {
        Write "{""content"":["
    }
    
    Set tName="",tFirst=1
    For {
        Set tName=$Order(i%DocArray(tName),1,tObj) Quit:tName=""
        
        If 'tFirst {
            If $Data(outstr) {
                Do outstr.Write(",")
            } Else {
                Write ","
            }
        } Else {
            Set tFirst=0
        }
        
        Do tObj.%ToJSON(.outstr)
    }
    
    If $Data(outstr) {
        Do outstr.Write("]}")
    } Else {
        Write "]}"
    }
}

}
