/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This is the base class for any Converter implementations. Converter classes are used during the processing
/// step to extract textual data and, optionally, source metadata from the context of different file formats.
/// If a converter is defined in the loading process, the processor will call this object to extract the required
/// data before the data is pushed to the iKnow Indexer.</p>
/// <p>Converter objects are handled by the loading framework automatically and custom code should
/// never instantiate a Converter object or call any of its methods directly.</p>
Class %iKnow.Source.Converter Extends %RegisteredObject [ Abstract, Deprecated, System = 4 ]
{

Property Params As %String;

Property MetaData As %List [ Internal, Private ];

Property CurrentRef As %List [ Internal, Private ];

Property DomainId As %Integer [ Internal, Private ];

Method %OnNew(params As %String) As %Status [ Private, ServerOnly = 1 ]
{
	set tSC = ..SetParams(params)
    Set a=1024 // Bogus workaround for class bug
    Quit tSC
}

/// <p>This method takes the raw input text and buffers it internally in the converter. The text is provided in
/// chunks of 32k. Every custom converter will need to implement this method so that it can take in the raw
/// data.</p>
Method BufferString(data As %String) As %Status
{
	quit $$$OK
}

/// <p>This method is called after all data has been buffered. In this method the converter will need to parse the
/// raw data and extract/convert it into plain text data. If any metadata is present within the document the converter
/// can extract that metadata here, and provide it to the system. Metadata can be reported by using the <method>SetCurrentMetadataValues</method>
/// function.</p>
Method Convert() As %Status
{
	quit $$$OK
}

/// <p>When conversion is done, this method will be called to fetch the converted data back from the converter. The method
/// should return the converted text in chuncks of maximum 32k in size. When no more data is available, the method should
/// return the empty string ("") to signal that all data has been transferred.</p>
Method NextConvertedPart() As %String
{
	quit ""
}

/// If the Converter extracts metadata, this method should return a list of keys of the metadata fields that are 
/// extracted from the contents. The values will be exposed in the <method>Convert</method> method in the same order as they are
/// reported here.
ClassMethod GetMetadataKeys(params As %String) As %List
{
	quit ""
}

Method GetMetadataValues() As %String [ Final, Internal ]
{
	quit i%MetaData
}

Method ResetMetadataValues() As %Status [ Final, Internal ]
{
	set i%MetaData = ""
	quit $$$OK
}

Method GetCurrentMetadataKeys() As %List [ Final, Internal ]
{
    Quit ..GetMetadataKeys(..Params)
}

/// <p>Use this function to report metadata from within the <method>Convert</method> function. The method takes a list of metadata values.
/// The values should be in the same order as the order of the keys as reported by the <method>GetMetadataKeys</method> method.</p>
Method SetCurrentMetadataValues(metaValues As %List) As %Status [ Final, Private ]
{
	quit:$ll(metaValues)'=$ll(..GetCurrentMetadataKeys()) $$$ERROR($$$IKMDValueCountMismatch, $ll(metaValues), $ll(..GetCurrentMetadataKeys()))
	set i%MetaData = metaValues
	quit $$$OK
}

Method SetContext(domainId As %Integer, ref As %List) As %Status [ Internal ]
{
	set i%DomainId = domainId
	set i%CurrentRef = ref
	quit $$$OK
}

/// <p>Utility method to report warnings for the current source, which won't disrupt further processing.</p>
/// <p><b>NOTE</b>: to report errors, simply pass back the error code as the output of <method>Convert</method> or <method>BufferString</method></p>
Method ReportWarning(ref As %List, message As %String, location As %String = "") As %Status [ Final, Private ]
{
	set:location="" location = ..%ClassName(1)
    Set ^IRIS.IKL.Warning(i%DomainId,$i(^IRIS.IKL.Warning(i%DomainId)))=$lb(ref,location,message,$h)
    Quit $$$OK
}

/// <p>Utility method called by the <class>%iKnow.Source.Processor</class> and <class>%iKnow.Source.Loader</class> 
/// logic to register any new or changed parameter values.</p>
Method SetParams(params As %String) As %Status
{
	set i%Params = $g(params)
	quit $$$OK
}

/// Utility method to test a converter class. <var>pInput</var> can be either a straight string,
/// or an array of string values that need to be concatenated. The result is a straight string.
ClassMethod Test(ByRef pInput As %String, pParams As %List = "", Output pSC As %Status) As %String
{
	set pSC = $$$OK, tConvertedText = ""
	try {
		set tConverter = ..%New(pParams)
		
		if $d(pInput)>1 {
			set i = ""
			for {
				set i = $order(pInput(i), 1, tText)
				quit:i=""
				set pSC = tConverter.BufferString(tText)
				quit:$$$ISERR(pSC)
			}
			quit:$$$ISERR(pSC)
		} else {
			set pSC = tConverter.BufferString(pInput)
			quit:$$$ISERR(pSC)
		}
		
		set pSC = tConverter.Convert()
		quit:$$$ISERR(pSC)
		
		while 1 {
			set tLine = tConverter.NextConvertedPart()
			quit:tLine=""
			set tConvertedText = tConvertedText _ tLine
		}
		
		set tConverter=""
		
	} catch (ex) {
		set pSC = ex.AsStatus()
	}
	quit tConvertedText
}

}
