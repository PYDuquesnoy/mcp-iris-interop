/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occInclude

/// 
/// Implementation of SQL support
/// 
Class %SYS.Python.SQLResultSet Extends %RegisteredObject [ System = 4 ]
{

/// 
/// Wrapped ResultSet
/// 
Property ResultSet As %SQL.StatementResult;

/// 
/// Indicate if we're already started iteration
/// 
Property IterationStarted As %Boolean [ InitialExpression = 0 ];

/// 
/// Implement %OnNew handler
/// 
Method %OnNew(rs As %SQL.StatementResult) As %Status
{
    Set ..ResultSet = rs
    Quit $$$OK
}

/// 
/// Grab an iterator
/// 
Method "__iter__"()
{
    If ..IterationStarted {
        Throw ##class(%SYS.Python).Import("builtins").EOFError
    }

    // Mark iteration as started
    Set ..IterationStarted = 1

    Quit $THIS
}

Method "__next__"() As %String
{
    #dim row As %List

    If '..ResultSet.%GetRow(.row,.sc) {
        Throw $system.Python.Builtins().StopIteration
    }

    If $$$ISERR(sc) {
        Throw ##class(SQL).raiseError(sc)
    }

    Set list = $system.Python.Builtins().list()
    For i=1:1:$LL(row) {
        Do list.append($LG(row,i))
    }

    Quit list
}

/// 
/// We don't know the length/size of a result set ...
/// 
Method "__len__"() As %Integer
{
    Throw $system.Python.Builtins().TypeError
}

/// 
/// We can't do a contains ...
/// 
Method "__contains__"() As %Boolean
{
    Throw $system.Python.Builtins().TypeError
}

/// 
/// Convert resultset to a Pandas dataframe
/// 
Method dataframe() As %SYS.Python
{
    If ..IterationStarted {
        Throw ##class(%SYS.Python).Import("builtins").EOFError
    }

    // We'll borrow the AutoML provider from Integrated ML
    Set provider = ##class(%ML.AutoML.Provider).%New()

    // Let's set up just the packages we need, loading automl loads tensorflow and
    // other stuff we don't want
    Set provider.builtins = $system.Python.Builtins()
    For pkg = "pandas", "numpy", "decimal", "datetime" {
        Set $PROPERTY(provider,pkg) = $system.Python.Import(pkg)
    }

    Set provider.initialized = 1

    // Mark iteration as started
    Set ..IterationStarted = 1

    // Now, convert this resultset into a dataframe
    Set sc = provider.%ResultSetToDataFrame(..ResultSet,, .df)
    If $$$ISERR(sc) {
        Throw ##class(SQL).raiseError(sc)
    }

    Quit df
}

}
