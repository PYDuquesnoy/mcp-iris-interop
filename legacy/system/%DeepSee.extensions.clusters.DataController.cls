/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.extensions.clusters.DataController [ Abstract, System = 4 ]
{

Property xValues As list Of %ZEN.Datatype.float;

Property yValues As list Of %ZEN.Datatype.float;

Property radius As list Of %ZEN.Datatype.float;

Property group As list Of %ZEN.Datatype.float;

Property defaultRadius As %ZEN.Datatype.float [ InitialExpression = 1 ];

ClientMethod getData(series) [ Language = javascript ]
{

	switch(series) {
		case 0:
			return this.xValues;
		case 1:
			return this.yValues;
		case 2:
			return this.radius;
		case 3:
			return this.group;
	}
}

Method %InsertDataPoint(k As %Integer, x As %Double, y As %Double, r As %Double = 1)
{
	set x = ..%Round(x)
	set y = ..%Round(y)
	
	do ..xValues.Insert(x)
	do ..yValues.Insert(y)
	do ..radius.Insert(..%Round(..defaultRadius*r))
	do ..group.Insert(k)
}

Method %GetSeriesSize() As %Integer
{
	Quit ..xValues.Count()
}

Method %SetDataPoint(k As %Integer, pos As %Integer, x As %Double, y As %Double)
{
	set x = ..%Round(x)
	set y = ..%Round(y)
	
	do ..xValues.SetAt(x,pos)
	do ..yValues.SetAt(y,pos)
	do ..radius.SetAt(..defaultRadius,pos)
	do ..group.SetAt(k,pos)
}

Method %ClearDataset()
{
	do ..xValues.Clear()
	do ..yValues.Clear()
	do ..radius.Clear()
	do ..group.Clear()
}

ClassMethod %Round(x As %Float) As %Float
{
	Quit $s($zabs(x)<0.0001:x,
			$zabs(x)<0.001:$fn(x,"",5),
			$zabs(x)<0.01:$fn(x,"",4),
			$zabs(x)<0.1:$fn(x,"",3),
			1:$fn(x,"",2)
		)
}

}
