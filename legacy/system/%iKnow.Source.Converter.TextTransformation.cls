/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This <class>%iKnow.Source.Converter</class> implementation wraps around a Text Transformation model
///  and will extract sections and key-value pairs as defined in the model. Select sections will be
///  concatenated and used as text input for indexing by the iKnow engine, while select key-value pairs
///  can be saved as metadata values.</p>
///  <p><b>Converter parameters:</b>
///  <ol>
///  <li><b>Model class name</b> (%String): name of the <class>%iKnow.TextTransformation.Definition</class> class
///  containing the TT model definition. This parameter is required.</li>
///  <li><b>Section headers to index</b> (%String, default = ""): comma-separated list of section headers whose contents is to 
///  be indexed. Leaving this parameter blank (default) will cause all sections to be indexed. Header names
///  are case-insensitive.</li>
///  <li><b>Include headers in sections</b> (%Boolean, default = 0): whether or not to include the header
///  itself to be indexed as well. Setting this value to 1 will ensure section contents is always prepended
///  with the title.</li>
///  <li><b>Keys to extract for metadata</b> (%String, default = ""): comma-separated list of keys the 
///  model extracts that need to be saved as metadata values. Leaving this parameter blank (default) will
///  result in no key-value pairs being saved as metadata. Key names are case-insensitive.</li>
///  <li><b>Metadata field names</b> (%String, default = ""): comma-separated list of metadata field names
///  corresponding to the key names in the third parameter. If left blank, it is assumed the key names
///  themselves are valid metadata field names.</li>
///  </ol>
Class %iKnow.Source.Converter.TextTransformation Extends %iKnow.Source.Converter [ Deprecated, System = 4 ]
{

Property Buffer [ MultiDimensional, Private ];

Property OutputText [ MultiDimensional, Private ];

Method BufferString(data As %String) As %Status
{
	set i%Buffer($i(i%Buffer)) = data
	quit $$$OK
}

/// <p>This method is called after all data has been buffered. In this method the converter will need to parse the
/// raw data and extract/convert it into plain text data. If any metadata is present within the document the converter
/// can extract that metadata here, and provide it to the system. Metadata can be reported by using the <method>SetCurrentMetadataValues</method>
/// function.</p>
Method Convert() As %Status
{
	set tSC = $$$OK
	try {
		
		// invoke TT model
		set tTTModel = $lg(..Params,1)
		merge tBuffer = i%Buffer
		set tSC = $classmethod(tTTModel, "%Apply", .tBuffer, .tOutput)
		quit:$$$ISERR(tSC)
		
		// assemble output text
		kill ..OutputText
		set tOutSectionCount = tOutput.GetSectionCount()
		set tSections = $zstrip($lg(..Params,2),"<>W"), tSectionCount = $l(tSections,",")
		set tIncludeHeaders = +$lg(..Params,3)
		if (tSections'="") {
			for i = 1:1:tSectionCount {
				set tSectionName = $$$UPPER($zstrip($piece(tSections,",",i),"<>W"))
				
				// now find sections with this name
				for j = 1:1:tOutSectionCount {
					set tOutSection = tOutput.GetSectionAt(j)
					continue:$$$UPPER(tOutSection.Header)'=tSectionName
					
					set:tIncludeHeaders i%OutputText($i(i%OutputText)) = tOutSection.Header_$c(13,10,13,10)
					set i%OutputText($i(i%OutputText)) = tOutSection.Text_$c(13,10,13,10)
				}
			}	
		} else {
			// if no specific headers requested, just concat all
			for j = 1:1:tOutSectionCount {
				set tOutSection = tOutput.GetSectionAt(j)
				set:tIncludeHeaders i%OutputText($i(i%OutputText)) = tOutSection.Header_$c(13,10,13,10)
				set i%OutputText($i(i%OutputText)) = tOutSection.Text_$c(13,10,13,10)
			}
		}
		
		// now retrieve requested key-value pairs
		set tKeys = $zstrip($lg(..Params,4),"<>W")
		if (tKeys'="") {
			set tKeyCount = $l(tKeys,","), tMetadataValues=""
			set tOutKeyCount = tOutput.GetKeyValueCount()
			for i = 1:1:tKeyCount {
				set tKey = $$$UPPER($zstrip($piece(tKeys,",",i),"<>W"))
				set tValue = ""
				for j = 1:1:tOutKeyCount {
					set tKeyValue = tOutput.GetKeyValueAt(j)
					continue:$$$UPPER(tKeyValue.Key)'=tKey
					set tValue = tKeyValue.Value
					quit
				}
				set tMetadataValues = tMetadataValues_$lb(tValue)
			}
			set tSC = ..SetCurrentMetadataValues(tMetadataValues)
			quit:$$$ISERR(tSC)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	
	// clear buffer
	kill i%Buffer
	
	quit tSC
}

ClassMethod GetMetadataKeys(params As %String) As %List
{
	set tKeys = $lg(params,5,$lg(params,4))
	quit $s(tKeys="":"", 1:$lts(tKeys))
}

/// <p>When conversion is done, this method will be called to fetch the converted data back from the converter. The method
/// should return the converted text in chuncks of maximum 32k in size. When no more data is available, the method should
/// return the empty string ("") to signal that all data has been transferred.</p>
Method NextConvertedPart() As %String
{
get	set tDataIndex = $i(i%OutputText(-1))
	if (tDataIndex > i%OutputText) { // done!
		kill i%OutputText, i%Buffer
		quit ""
	}
	set tData = $g(i%OutputText(tDataIndex))
	goto:tData="" get
	quit tData
}

}
