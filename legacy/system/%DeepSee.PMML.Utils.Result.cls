/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Utils.Result Extends %RegisteredObject [ Abstract, System = 4 ]
{

Property TestId As %Integer;

Property ModelClass As %String(MAXLEN = 2000);

Property TestRecordId As %String(MAXLEN = 2000);

Property ActualValue As %String(MAXLEN = 2000);

Property PredictedValue As %String(MAXLEN = 2000);

Property PredictTime As %TimeStamp;

Property Probability As %Double;

Property OutputFields As %ArrayOfDataTypes;

ClassMethod GetNewTestId() As %Integer [ Abstract ]
{
}

}
