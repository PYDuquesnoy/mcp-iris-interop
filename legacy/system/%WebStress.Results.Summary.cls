/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %WebStress.Results.Summary Extends (%Persistent, %XML.Adaptor) [ Inheritance = right, Owner = {%Developer}, System = 4 ]
{

Property RunID As %Integer;

Property TestID As %String(TRUNCATE = 1);

Property Script As %String(TRUNCATE = 1);

Property Generator As %String(TRUNCATE = 1);

Property Verb As %String(TRUNCATE = 1);

Property Path As %String(TRUNCATE = 1);

Property URL As %Integer;

Property CharactersSentMin As %Integer;

Property CharactersSentMax As %Integer;

Property CharactersSentTotal As %Integer;

Property CharactersSentAvg As %Numeric(SCALE = 1);

Property CharactersSentStdDev As %Numeric(SCALE = 1);

Property CharactersRecMin As %Integer;

Property CharactersRecMax As %Integer;

Property CharactersRecTotal As %Integer;

Property CharactersRecAvg As %Numeric(SCALE = 1);

Property CharactersRecStdDev As %Numeric(SCALE = 1);

Property TTFCMin As %Integer;

Property TTFCMax As %Integer;

Property TTFCTotal As %Integer;

Property TTFCAvg As %Numeric(SCALE = 1);

Property TTFCStdDev As %Numeric(SCALE = 1);

Property TTLCMin As %Integer;

Property TTLCMax As %Integer;

Property TTLCTotal As %Integer;

Property TTLCAvg As %Numeric(SCALE = 1);

Property TTLCStdDev As %Numeric(SCALE = 1);

Index Main On (TestID, RunID, Script, Generator, URL) [ IdKey, PrimaryKey, Unique ];

ClassMethod Summary(testID As %String, runID As %Integer)
{
	// We will keep the results in a temporary global so get rid of it first
	// Use ^IRIS.Temp so as to get the full performance benefit
	kill ^IRIS.Temp.WebStress.Temp($job)
	&sql(declare SUMMARY cursor for
		select Script,Generator,URL,Verb,Path,CharactersSent,CharactersReceived,TimeToFirstCharacter,TimeToLastCharacter
		into :script,:generator,:url,:verb,:path,:chars,:charr,:TTFC,:TTLC
		from %WebStress_Results.Calls
		where (TestID = :testID) and (RunID = :runID))
	&sql(open SUMMARY)
	for  {
		&sql(fetch SUMMARY)
		if SQLCODE'=0 quit
		set data=$get(^IRIS.Temp.WebStress.Temp($job,script,generator,url))
		if data="" {
			set data=$lb("",1,verb,path,chars,chars,chars,chars,(chars*chars),charr,charr,charr,charr,(charr*charr),TTFC,TTFC,TTFC,TTFC,(TTFC*TTFC),TTLC,TTLC,TTLC,TTLC,(TTLC*TTLC))
		}
		else {
			set count=$li(data,2)+1,$li(data,2)=count
			if chars<$li(data,5) set $li(data,5)=chars
			if chars>$li(data,6) set $li(data,6)=chars
			set $li(data,7)=$li(data,7)+chars
			set $li(data,8)=$li(data,7)/count
			set $li(data,9)=$li(data,9)+(chars*chars)
			
			if charr<$li(data,10) set $li(data,10)=charr
			if charr>$li(data,11) set $li(data,11)=charr
			set $li(data,12)=$li(data,12)+charr
			set $li(data,13)=$li(data,12)/count
			set $li(data,14)=$li(data,14)+(charr*charr)
			
			if TTFC<$li(data,15) set $li(data,15)=TTFC
			if TTFC>$li(data,16) set $li(data,16)=TTFC
			set $li(data,17)=$li(data,17)+TTFC
			set $li(data,18)=$li(data,17)/count
			set $li(data,19)=$li(data,19)+(TTFC*TTFC)
			
			if TTLC<$li(data,20) set $li(data,20)=TTLC
			if TTLC>$li(data,21) set $li(data,21)=TTLC
			set $li(data,22)=$li(data,22)+TTLC
			set $li(data,23)=$li(data,22)/count
			set $li(data,24)=$li(data,24)+(TTLC*TTLC)
		}
		set ^IRIS.Temp.WebStress.Temp($job,script,generator,url)=data
	}
	&sql(close SUMMARY)
	set script=""
	for  {
		set script=$order(^IRIS.Temp.WebStress.Temp($job,script))
		if script="" quit
		set generator=""
		for  {
			set generator=$order(^IRIS.Temp.WebStress.Temp($job,script,generator))
			if generator="" quit
			set url=""
			for  {
				set url=$order(^IRIS.Temp.WebStress.Temp($job,script,generator,url),1,data)
				if url="" quit
				set count=$li(data,2)-1
				for i=9,14,19,24 {
					set value=$li(data,i)
					if count>0 {
						set value=value/count
						set value=value**.5
					}
					else {
						set value=""
					}
					set $li(data,i)=value
				}
				set ^IRIS.Temp.WebStress.Temp($job,script,generator,url)=data
			}
		}
	}
	kill ^WebStress.Results.SummaryD(testID,runID)
	merge ^WebStress.Results.SummaryD(testID,runID)=^IRIS.Temp.WebStress.Temp($job)
	kill ^IRIS.Temp.WebStress.Temp($job)
}

Query GetData(testID As %String, runID As %Integer) As %SQLQuery
{
SELECT Script,Generator,URL,Verb,Path,CharactersSentMin,CharactersSentMax,CharactersSentTotal,CharactersSentAvg,CharactersSentStdDev,CharactersRecMin,CharactersRecMax,CharactersRecTotal,CharactersRecAvg,CharactersRecStdDev,TTFCMin,TTFCMax,TTFCTotal,TTFCAvg,TTFCStdDev,TTLCMin,TTLCMax,TTLCTotal,TTLCAvg,TTLCStdDev FROM Summary
 WHERE (TestID = :testID AND RunID = :runID)
}

Storage Default
{
<Data name="ResultsSummaryDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="3">
<Value>Verb</Value>
</Value>
<Value name="4">
<Value>Path</Value>
</Value>
<Value name="5">
<Value>CharactersSentMin</Value>
</Value>
<Value name="6">
<Value>CharactersSentMax</Value>
</Value>
<Value name="7">
<Value>CharactersSentTotal</Value>
</Value>
<Value name="8">
<Value>CharactersSentAvg</Value>
</Value>
<Value name="9">
<Value>CharactersSentStdDev</Value>
</Value>
<Value name="10">
<Value>CharactersRecMin</Value>
</Value>
<Value name="11">
<Value>CharactersRecMax</Value>
</Value>
<Value name="12">
<Value>CharactersRecTotal</Value>
</Value>
<Value name="13">
<Value>CharactersRecAvg</Value>
</Value>
<Value name="14">
<Value>CharactersRecStdDev</Value>
</Value>
<Value name="15">
<Value>TTFCMin</Value>
</Value>
<Value name="16">
<Value>TTFCMax</Value>
</Value>
<Value name="17">
<Value>TTFCTotal</Value>
</Value>
<Value name="18">
<Value>TTFCAvg</Value>
</Value>
<Value name="19">
<Value>TTFCStdDev</Value>
</Value>
<Value name="20">
<Value>TTLCMin</Value>
</Value>
<Value name="21">
<Value>TTLCMax</Value>
</Value>
<Value name="22">
<Value>TTLCTotal</Value>
</Value>
<Value name="23">
<Value>TTLCAvg</Value>
</Value>
<Value name="24">
<Value>TTLCStdDev</Value>
</Value>
</Data>
<DataLocation>^WebStress.Results.SummaryD</DataLocation>
<DefaultData>ResultsSummaryDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^WebStress.Results.SummaryD</IdLocation>
<IndexLocation>^WebStress.Results.SummaryI</IndexLocation>
<StreamLocation>^WebStress.Results.SummaryS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
