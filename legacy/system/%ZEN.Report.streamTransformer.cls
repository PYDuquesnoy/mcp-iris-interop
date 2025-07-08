/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// 
Class %ZEN.Report.streamTransformer Extends %RegisteredObject [ Deprecated, System = 4 ]
{

/// expand macro definitions in stream
ClassMethod transformStream(ByRef pinStream As %Stream.TmpCharacter, ByRef poutStream As %Stream.TmpCharacter) As %Status
{
	Set tSC=$$$OK
	do {
		Set poutStream=##class(%Stream.TmpCharacter).%New()
		Set tSC=##class(%XML.TextReader).ParseStream(pinStream,.textReader)
		if $$$ISERR(tSC) quit 
		Set prefixmapping=0
		while (textReader.Read()) {
			if (textReader.NodeType="element") {
				if (textReader.Name="macrodef") {
					if (textReader.AttributeCount'=2) {
						set tSC=$$$ERROR($$$GeneralError,"Error while transforming stream macrodef must have 2 arguments")
						
					} else {
						Set classname=""
						Set xdataname=""
						for i=1:1:textReader.AttributeCount {
							Set flag=textReader.MoveToAttributeIndex(i)
							if (textReader.Name="class") {
								Set classname=textReader.Value
							} elseif (textReader.Name="xdata") {
								Set xdataname=textReader.Value
							}
						}
						if (classname="") {
							set tSC=$$$ERROR($$$GeneralError,"Error while transforming stream macrodef must have non-null class")
							quit
						}
						if (xdataname="") {
							set tSC=$$$ERROR($$$GeneralError,"Error while transforming stream macrodef must have non-null xdata")
							quit
						}
						Set me = ##class(%Dictionary.CompiledClass).%OpenId(classname)
						if ($isObject(me)) {
	    					Set idx = me.XDatas.FindObjectId(classname_"||"_xdataname)
							if (idx="") {
					     		Set tSC=$$$ERROR($$$GeneralError,"Could not find XDATA class="_classname_" xdata="_xdataname)
					     		quit
							}
							Set data = me.XDatas.GetAt(idx).Data
							if $isObject(data) {
								Do data.Rewind()
								Set chunksize=32000
								
									
								While 'data.AtEnd {
									Set chunk=data.Read(chunksize)
									While $f(chunk,"<zenxslt>") || $f(chunk,"</zenxslt>") {									
										if $f(chunk,"<zenxslt>") {
											Set beg=$f(chunk,"<zenxslt>")-$L("<zenxslt>")-1
											Set end=$f(chunk,"<zenxslt>",beg)
										} else {
											Set beg=$f(chunk,"</zenxslt>")-$L("</zenxslt>")-1
											Set end=$f(chunk,"</zenxslt>",beg)
										}
										Set chunk=$e(chunk,1,beg)_$e(chunk,end,$l(chunk))
									}
									Do poutStream.Write(chunk)
								}	
							} else {
								Set tSC=$$$ERROR($$$GeneralError,"Could not get XDATA class="_classname_" xdata="_xdataname)
							}
						 } else {
							 Set tSC=$$$ERROR($$$GeneralError,"Could not open the class of the XDATA class="_classname_" xdata="_xdataname)
						 }
			
					}
				}
				elseif (textReader.HasAttributes) {
					Do poutStream.Write("<"_textReader.Name)
					Do ..DumpPrefixMapping(poutStream, .prefixmapping)
					for i=1:1:textReader.AttributeCount {
						Set flag=textReader.MoveToAttributeIndex(i)
						if textReader.HasValue  {
							Set value=$ZCVT(textReader.Value,"O","XML")
							Do poutStream.Write(" "_textReader.Name_"="_""""_value_"""")
						}
						
					}
					Do poutStream.WriteLine(">")
					Set prefixmapping=0
				} else {
					Do poutStream.Write("<"_textReader.Name)
					Do ..DumpPrefixMapping(poutStream, .prefixmapping)
					Do poutStream.WriteLine(">")
				}
			}
			elseif (textReader.NodeType="chars") {
				if textReader.HasValue Do poutStream.Write(textReader.Value)
			} elseif (textReader.NodeType="comment") {
				if textReader.HasValue Do poutStream.WriteLine("<!--"_textReader.Value_"-->")
			} elseif (textReader.NodeType="error") {
				Set tSC=$$$ERROR($$$GeneralError,"Error while transforming stream "_textReader.Value)
			} elseif (textReader.NodeType="processinginstruction") {
				if textReader.HasValue Do poutStream.WriteLine("<?"_textReader.Name_" "_textReader.Value_"?>")
			} elseif (textReader.NodeType="startprefixmapping") {
				
				if textReader.HasValue {
					Set prefixmapping=$i(prefixmapping)
					if (textReader.Name'="") {
						Set prefixmapping(prefixmapping,"Name")=textReader.Name
						Set prefixmapping(prefixmapping,"Value")=textReader.Value
						;Do poutStream.WriteLine(" xmlns:"_textReader.Name_"='"_textReader.Value_"'")
					} else {
						Set prefixmapping(prefixmapping,"Name")=textReader.Name
						Set prefixmapping(prefixmapping,"Value")=textReader.Value

						;Do poutStream.WriteLine(" xmlns='"_textReader.Value_"'")
					}
				}
			} elseif (textReader.NodeType="endprefixmapping") {
				;Do poutStream.WriteLine(" End prefix mapping")
			}
			elseif (textReader.NodeType="endelement") {
				if textReader.Name'="macrodef" Do poutStream.WriteLine("</"_textReader.Name_">")
			} elseif (textReader.NodeType="ignorablewhitespace") {
				Do poutStream.WriteLine(textReader.Value)
			}
			if $$$ISERR(tSC) quit
		}
	} while (0) ;
	Do poutStream.Rewind()
	;Do poutStream.OutputToDevice()
	quit tSC
}

ClassMethod DumpPrefixMapping(ByRef poutStream As %Stream.TmpCharacter, ByRef prefixmapping As %String)
{
	for i=1:1:prefixmapping {
		Set value=$zstrip(prefixmapping(i,"Value"),"<>W")
		if (prefixmapping(i,"Name")) {
			Do poutStream.Write(" xmlns:"_prefixmapping(i,"Name")_"="""_value_"""")
		} else {
			Do poutStream.Write(" xmlns="""_value_"""")
		}

	}

	Set prefixmapping = 0
}

}
