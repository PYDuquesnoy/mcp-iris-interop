/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ZEN.Report.DataCache Extends %RegisteredObject [ Deprecated, System = 4 ]
{

Property globalindex As %Integer;

Property counter As %ZEN.Report.RecordCounter;

Property saveCounter As %Integer;

Property saveArray [ MultiDimensional ];

Property atEnd [ InitialExpression = 0 ];

Property AtEndValues [ MultiDimensional ];

Property AtEndValue;

Method %unfetch()
{
	Set ..counter.currentrow=..counter.currentrow-1
}

Method %fetch()
{
	Set ..counter.currentrow=..counter.currentrow+1
}

Method %save()
{
	Set ..saveCounter=..counter.currentrow
	Set ..AtEndValue = ..atEnd
}

Method %restore()
{
	Set ..counter.currentrow=..saveCounter
	Set ..atEnd = ..AtEndValue
}

Method %put(pLevel As %Integer, n As %Integer)
{
	Set ..saveArray(pLevel,n)=..counter.currentrow
	Set ..AtEndValues(pLevel,n)=..atEnd
}

Method %set(n As %Integer)
{
	Set ..counter.currentrow=n
	if (n > ..counter.totalRows) s ..atEnd=1
	else  Set ..atEnd=0
}

Method %get(pLevel As %Integer, n As %Integer) As %Integer
{
	Set retVal=..counter.currentrow
	if '$D(..saveArray(pLevel,n)) quit retVal
	Set ..counter.currentrow=..saveArray(pLevel,n)
	Set ..atEnd=..AtEndValues(pLevel,n)
	q retVal
}

Method %atEnd() As %Boolean
{
	quit ..counter.currentrow'<..counter.totalRows
}

}
