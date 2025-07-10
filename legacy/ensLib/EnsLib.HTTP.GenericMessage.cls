/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Transport contents of an HTTP request or response through InterSystems IRIS
Class EnsLib.HTTP.GenericMessage Extends Ens.StreamContainer [ System = 4 ]
{

Parameter XMLTYPE = "HTTPMessage";

Parameter XMLNAME = "HTTPMessage";

/// An array of strings containing any HTTP header values
Property HTTPHeaders As array Of %String(MAXLEN = "");

Method %OnNew(pBodyStream As %RawString = {$$$NULLOREF}, pAttributes As %Collection.ArrayOfDT = {$$$NULLOREF}, pHTTPHeaders As %Collection.ArrayOfDT = {$$$NULLOREF}) As %Status
{
	Set tSC=##super(pBodyStream,.pAttributes)  Quit:$$$ISERR(tSC) tSC
	Do ..SetHTTPHeaders(.pHTTPHeaders)
	Quit $$$OK
}

/// Set values into the HTTPHeaders array property
/// Pass in an array object, a ObjectScript array, a ObjectScript array reference, a %AbstractStream with its own Attributes to copy from, a %Net.HttpResponse object with its own Headers to copy from, or a string of the form 'a=1,b=2,c=3'.
Method SetHTTPHeaders(ByRef pHTTPHeaders)
{
	If $IsObject(pHTTPHeaders) {
		If pHTTPHeaders.%Extends("%Collection.ArrayOfDT") {
			Set ..HTTPHeaders=pHTTPHeaders
		} ElseIf pHTTPHeaders.%Extends("%ArrayOfDataTypes") {
			Set ..HTTPHeaders=pHTTPHeaders
		} ElseIf pHTTPHeaders.%Extends("%Net.HttpResponse") {
			Set k="" For { Set k=$O(pHTTPHeaders.Headers(k),1,val)  Quit:""=k
				Do ..HTTPHeaders.SetAt(val,k)
			}
		} ElseIf pHTTPHeaders.%Extends("%AbstractStream") {
			Set k="" For { Set k=$O(pHTTPHeaders.Attributes(k),1,val)  Quit:""=k
				Do:k'="Params" ..HTTPHeaders.SetAt(val,k)
				If k="IParams" {
					For i=1:1:val { Set pval=$G(pHTTPHeaders.Attributes("IParams",i))
						Do ..HTTPHeaders.SetAt(pval,"IParams_"_i)
					}
				}
			}
		} ElseIf pHTTPHeaders.%Extends("%CSP.Stream") {
			Set k="" For { Set k=pHTTPHeaders.NextAttribute(k)  Quit:""=k
				If (",Params,LineTerminator,FileName,ContentType,CharSet,Expires,MimeSection,Headers,"[(","_k_",")) {
					/* Skip */
				} ElseIf k="IParams" {
					Set val=pHTTPHeaders.GetAttribute("IParams",0)
					For i=1:1:val {
						Try {
							Set pval=pHTTPHeaders.Attributes("IParams",i)
							Do ..HTTPHeaders.SetAt(pval,"IParams_"_i)
						} Catch {/* Protect against undefined */}
					}
					If val Do ..HTTPHeaders.SetAt(val,"IParams")
				} Else {
					Do ..HTTPHeaders.SetAt(pHTTPHeaders.Attributes(k),k)
				}
			}
		}
	} ElseIf pHTTPHeaders["=" {
		For i=1:1:$L(pHTTPHeaders,",") { Set k=$P(pHTTPHeaders,",",i)  Set val=$ZStrip($P(k,"=",2),"<>W"), k=$ZStrip($P(k,"="),"<>W") Continue:""=k  
			Do ..HTTPHeaders.SetAt(val,k)
		}
	} ElseIf ""'=pHTTPHeaders {
		Set k="" For { Set k=$O(@pHTTPHeaders@(k),1,val)  Quit:""=k
			Do ..HTTPHeaders.SetAt(val,k)
		}
	} ElseIf $D(pHTTPHeaders)>1 {
		Set k="" For { Set k=$O(pHTTPHeaders(k),1,val)  Quit:""=k
			Do ..HTTPHeaders.SetAt(val,k)
		}
	}
}

ClassMethod %OnDelete(oid As %ObjectIdentity) As %Status [ Private ]
{
	New %tID  Set %tID=$$$oidPrimary(oid)
	Do ##class(Ens.SearchTableBase).RemoveSearchTableEntries($classname(),%tID,1)
	Quit $$$OK
}

Trigger OnDelete [ Event = DELETE ]
{
	New %tID  Set %tID={%%ID}
	Do ##class(Ens.SearchTableBase).RemoveSearchTableEntries($classname(),%tID,1)
	Quit
}

Storage Default
{
<Data name="HTTPHeaders">
<Attribute>HTTPHeaders</Attribute>
<Structure>subnode</Structure>
<Subscript>"EnsLib.HTTP.GenericMessage.HTTPHeaders"</Subscript>
</Data>
<Type>%Storage.Persistent</Type>
}

}
