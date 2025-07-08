/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ZEN.Report.Display.COSChart.dataItem Extends %RegisteredObject [ Deprecated ]
{

Property value As %Double;

Property itemNo As %Integer;

Method %OnNew(value, itemNo) As %Status
{
		Set ..value=value
		Set ..itemNo = itemNo
		quit $$$OK
}

ClassMethod sort(ByRef dataItems) [ Internal ]
{
	Set dataItemsLength=0
	// sort array of dataItem by value
	Set i="" For { Set i=$O(dataItems(i),1, dataItem) q:i=""
		Set sort(dataItem.value,dataItem.itemNo)=dataItem
		Set dataItemsLength = dataItemsLength+1
	}
	Set i=0
	Set value="" For { Set value=$O(sort(value),-1) q:value=""
		Set itemNo="" For { Set itemNo=$O(sort(value,itemNo)) q:itemNo=""
			Set dataItems(i)=sort(value,itemNo)
			Set i=i+1
		}
			
	}
}

ClassMethod splice(ByRef dataItems, start, chopOff) [ Internal ]
{
	// This emulates the JavaScript splice function for the cTreeMap code
	// The current implementation assumes start is 0
	if (start'=0) {
		w !,Unimplmented
	}
	Set length=..length(.dataItems)
	Set i="" for { Set i=$O(dataItems(i)) q:(i="")||(i>=(length-chopOff))
		// [1,2,3,4] when chopOff=2 becomes [1,2]
		// index 0 becomes index 2
		Set splicedData(i)=dataItems(i+chopOff)
	}
	kill dataItems
	Set i="" for { Set i=$O(splicedData(i),1,dataItem) q:(i="")
		Set dataItems(i)=dataItem
	}
}

ClassMethod length(ByRef dataItems) [ Internal ]
{
	Set dataItemsLength=0
	// sort array of dataItem by value
	Set i="" For { Set i=$O(dataItems(i)) q:i=""
		Set dataItemsLength = dataItemsLength+1
	}
	quit dataItemsLength ;
}

}
