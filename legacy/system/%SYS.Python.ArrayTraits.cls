/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occInclude

/// 
/// Implementation of Array traits for Python
/// 
Class %SYS.Python.ArrayTraits [ System = 4 ]
{

Projection Traits As %SYS.Python.Traits(TARGETSPEC = "%Collection.AbstractArray");

ClassMethod "__len__"(self As %Collection.AbstractArray) As %Integer [ Internal ]
{
    Quit self.Count()
}

ClassMethod "__getitem__"(self As %Collection.AbstractArray, key As %Any) As %Any [ Internal ]
{
    Set value = self.GetAt(key)
    If value'="" {
       Return value
    }

    Throw $system.Python.Builtins().KeyError
}

ClassMethod get(self As %Collection.AbstractArray, key As %Any, default As %Any) As %Any [ Internal ]
{
    Set value = self.GetAt(key)
    If value'="" {
        Return value
    }

    If default '= "" {
        Return default
    }

    Throw $system.Python.Builtins().KeyError
}

ClassMethod pop(self As %Collection.AbstractArray, key As %Any, default As %Any = "") As %Any [ Internal ]
{
    Set value = self.RemoveAt(key)
    If value'="" {
        Return value
    }

    If default '= "" {
        Return default
    }

    Throw $system.Python.Builtins().KeyError
}

ClassMethod popitem(self As %Collection.AbstractArray) As %SYS.Python [ Internal ]
{
    Set key = ""
    Set value = self.GetNext(.key)
    If key'="" {
        Do self.RemoveAt(key)

        Set list = $system.Python.Builtins().list()
        Do list.append(key)
        Do list.append(value)

        Return $system.Python.Builtins().tuple(list)
    }

    Throw $system.Python.Builtins().KeyError
}

ClassMethod "__contains__"(self As %Collection.AbstractArray, key As %Any) As %Boolean [ Internal ]
{
    Quit $CASE(self.IsDefined(key),0:0,:1)
}

ClassMethod "__setitem__"(self As %Collection.AbstractArray, key As %Any, value As %Any) [ Internal ]
{
    Do self.SetAt(value,key)
}

ClassMethod "__delitem__"(self As %Collection.AbstractArray, key As %Any) [ Internal ]
{
    Do self.RemoveAt(key)
}

ClassMethod clear(self As %Collection.AbstractArray) [ Internal ]
{
    Do self.Clear()
}

ClassMethod copy(self As %Collection.AbstractArray) As %Collection.AbstractArray [ Internal ]
{
    Quit self.%ConstructClone()
}

ClassMethod "__iter__"(self As %Collection.AbstractArray) [ Internal ]
{
    // NOTE: Iterating on a dict() actually returns the keys by default
    Quit ##class(IteratorHelper).%New(self,"keys")
}

ClassMethod items(self As %Collection.AbstractArray) [ Internal ]
{
    // Returns tuples of key,value
    Quit ##class(IteratorHelper).%New(self,"both")
}

ClassMethod keys(self As %Collection.AbstractArray) [ Internal ]
{
    Quit ##class(IteratorHelper).%New(self,"keys")
}

ClassMethod values(self As %Collection.AbstractArray) [ Internal ]
{
    Quit ##class(IteratorHelper).%New(self,"values")
}

}
