/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ZEN.Report.Display.COSChart.dataItemBullsEye Extends %RegisteredObject [ Deprecated ]
{

Property value As %Double;

Property itemNo As %Integer;

Property label As %String;

Property r As %Double;

Method %OnNew(value, itemNo, label) As %Status
{
		Set ..value=value
		Set ..itemNo = itemNo
		Set ..label = label
		quit $$$OK
}

ClassMethod sort(ByRef dataItems) [ Internal ]
{
	Set dataItemsLength=0
	// sort array of dataItem by value
	Set i="" For { Set i=$O(dataItems(i),1, dataItem) q:i=""
		Set sort(dataItem.value,dataItem.itemNo,dataItem.label)=dataItem
		Set dataItemsLength = dataItemsLength+1
	}
	Set i=0
	Set value="" For { Set value=$O(sort(value),-1) q:value=""
		Set itemNo="" For { Set itemNo=$O(sort(value,itemNo)) q:itemNo=""
			Set label="" For { Set label=$O(sort(value,itemNo,label)) q:label=""
			Set dataItems(i)=sort(value,itemNo,label)
			Set i=i+1
			}
		}
			
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
