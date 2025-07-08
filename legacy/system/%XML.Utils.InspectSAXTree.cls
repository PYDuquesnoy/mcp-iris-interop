/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%soap, %occSAX)

/// Support Utility to review contents of SAXTree independently from XML Writer functionality.<br/>
/// Provides convenience methods ParseFile, ParseString, ParseStream and ParseXData for common support situations.
/// Alternatively the method "OutputTree" can be called directly for additional scenarios.
Class %XML.Utils.InspectSAXTree
{

Parameter Indent = 1;

/// Display name used to indicate an element type
Parameter lblElement = "e";

/// Display name used to indicate an attribute type
Parameter lblAttribute = "a";

/// Display name used to indicate a whitespace node type
Parameter lblWhiteSpaceNode = "wsn";

/// Display name used to indicate a text node type
Parameter lblTextNode = "txt";

/// Display name used to indicate a raw node type
Parameter lblRAWNode = "raw";

Parameter NewLine = {$C(13,10)};

Parameter pad = "                                                                                    ";

/// xmlGbl = %SAX variable passed by reference
/// Support user entry point
/// Parameters:<br/>
/// <ul>
/// <li><var>xmlGbl</var> - Optional. The name of the local global being used to hold a SAX tree.<br/>
/// If not supplied this will default to %SAX global
/// </li>
/// <li><var>docSequence</var> - Optional. The %SAX global (or alternative global) first key is an incrementing sequence for each XML document deserialized into XML Nodes.
/// ie: %SAX(docSequence)<br/>
/// If not supplied the highest document id incremented is assumed to be the current one of interest. </li>
/// <li><var>nodeId</var> - Optional. The starting point in the SAX Tree to start analysis from. Typically would want to walk the whole document tree from 0.</li>
/// <li><var>outstream</var> - Optional. If not supplied when the tool is run it will output to default device, for example the window of an interactive terminal session.
/// Alternatively an open file stream can be passed in and output will be written to the file.
/// </li>
/// <li>dumpBinary - Optional. Some additional presentation of binary SAX tree portion that may be of value.</li>
/// </ul>
/// Example to output to terminal session (or other default device):
/// <example>
/// 
/// 
/// do ##class(Util.SAXDebugWriter).OutputTree()
/// </example>
/// Example to output to a file:
/// <example>
/// Set stream=##class(%FileBinaryStream).%New()
/// 	set stream.Filename="c:\tmp\SAXDebug"_msgId_"LoadedSimple.txt"
/// 	do ##class(Util.SAXDebugWriter).OutputTree(,simpleDocId,,.stream)
/// 	do stream.%Save()
/// 	do stream.%Close()
/// </example>
ClassMethod OutputTree(ByRef xmlGbl = "", docSequence = 0, nodeId = 0, outstream As %CharacterStream = {$$$NULLOREF}, dumpBinary = 0) [ PublicList = %SAX ]
{
	if '$IsObject(outstream) {
		set outstream=##class(%Stream.TmpCharacter).%New()
		set tmp=1
	} else {
		set tmp=0
	}

    // This is not pretty but needed to work around
    // quoted numerics being emitted from $$$xmlaGetChildList
    // Subsequent cascade of marcros doesn't have autoquote limitation 
    if $D(xmlGbl)>1 {
		set:docSequence<1 docSequence=$O(xmlGbl(""),-1)
        set DocId="xmlGbl(+"_docSequence_")"
        set d=$zlascii(xmlGbl(docSequence,0),29)
        set baseChildList=xmlGbl(docSequence,d\16)
		// Optional binary tree walking
		do:dumpBinary ..DumpBinaryTree(.xmlGbl,docSequence, outstream)
    } else {
		set:docSequence<1 docSequence=$O(%SAX(""),-1)
        set DocId="%SAX(+"_docSequence_")"
        set d=$zlascii(%SAX(docSequence,0),29)
        set baseChildList=%SAX(docSequence,d\16)
		// Optional binary tree walking
		do:dumpBinary ..DumpBinaryTree(.%SAX,docSequence, outstream)
    }
    // Piece1 is Key2 as in %SAX(1,Key2)
    // Piece2 is $Length characters offset of the binary tree node. The ZLAscii can be applied to this to find the real Key2 of the first node ie: %SAX(1,1)
    // Offset 29 when ZLAcii'ed will have value of key2 child nodeid 
    set NodeId=nodeId_","_29

	// Main tree walking
    Set tSC=..TreeInternal(DocId,NodeId,baseChildList,0,outstream)
    if $$$ISERR(tSC) {
        Do $SYSTEM.Status.DisplayError(tSC)
    }
	if tmp {
		do outstream.Rewind()
		do outstream.OutputToDevice()
	}
}

/// Optional binary tree walking
/// Normal operation would be to invoke OutputTree method instead.
/// Parameters:<br/>
/// <ul>
/// <li><var>xmlGbl</var> - Required. Pass local global by reference, being used to hold a SAX tree. eg: .%SAX<br/>
/// </li>
/// <li><var>docId</var> - Required. The %SAX global (or alternative global) first key is an incrementing sequence for each XML document deserialized into XML Nodes.<br/>
/// ie: for %SAX(docId) would pass first key docId</li>
/// <li><var>outstream</var> - Optional. If not supplied when the tool is run it will output to default device, for example the window of an interactive terminal session.
/// Alternatively an open file stream can be passed in and output will be written to the file.</li>
/// </ul>
ClassMethod DumpBinaryTree(ByRef xmlGbl = "", docId = "", outstream As %Stream.Object = {$$$NULLOREF})
{
	if docId="" {
		W !,"DumpBinaryTree no DocId specified"
		quit
	}
	if '$IsObject(outstream) {
		set outstream=##class(%Stream.TmpCharacter).%New()
		set tmp=1
	} else {
		set tmp=0
	}
	// This is a loop on key2 of %SAX document
	for k2=0:1:xmlGbl(docId) { 
		do ..DumpBinaryNode(.xmlGbl,docId,k2,outstream)
	}
	// If called directly instead of via OutputTree by default will output to default device.
	if tmp {
		do outstream.Rewind()
		do outstream.OutputToDevice()
	}
}

/// Currently only working for %SAX
ClassMethod DumpBinaryNode(ByRef xmlGbl = "", docId = 1, nodeId = 0, outstream As %Stream.Object) [ Internal ]
{
	set value=$G(xmlGbl(docId,nodeId))
    quit:value=""
    set parent=$ZLA(value,1)  // xmlGbl(docId, parent)
    set offset=$ZLA(value,5)   // $Length offset within xmlGbl(docId, parent) ; pointer in parent back to this nodeid
    set name=$ZLA(value,9)   // Element Name
    set prefix=$ZLA(value,13)\16
    set flags=$ZLA(value,13)#16
    set elementOffset=$ZWA(value,17)
    set URI=$ZWA(value,19)
    set line=$ZLA(value,21)
    set column=$ZLA(value,25)

    set next=$ZLA(value,$L(value)-3)

    set hasChildNodes=$L(value)>(elementOffset+4)

	do outstream.Write(..#NewLine_"  parent:"_parent_", offset:"_offset_", ElementName:"_name_" ("_$G(xmlGbl(docId,"d",name))_")")
	do outstream.Write(..#NewLine_"    flags:"_flags_", elementOffset:"_elementOffset_", URI:"_URI)
	do outstream.Write(..#NewLine_"    line:"_line_", column:"_column_", next:"_next_", length:"_$L(value))

	set hasAttributes=((elementOffset>29)&&($L(value)>33))
	if hasAttributes {
		do outstream.Write(..#NewLine_"    Attributes:")

		set end=elementOffset-4
    	for child=29:16:end {
			
			set name=$ZLA(value,child)
			do outstream.Write(..#NewLine_"        name ("_name_")="_..FormatText($G(xmlGbl(docId,"d",name)," ")))
			set valueAtt=$ZLA(value,child+12)
			do outstream.Write(..#NewLine_"          value ("_valueAtt_")="_..FormatText($G(xmlGbl(docId,"d",valueAtt)," ")))
    	}

	}

	set hasChildNodes=$L(value)>(elementOffset+4)

	if hasChildNodes {
		do outstream.Write(..#NewLine_"    Children:")

		do outstream.Write(..#NewLine_..PadTxt("Step",8)_..PadTxt("Descriptor",12)_..PadTxt("d node",8)_..PadTxt("Type",12)_..PadTxt("Value starts with",20))
		set end=$L(value)-4
    	for child=elementOffset:4:end {
    	    set desc=$ZLA(value,child)
			set nodeType=$Case(desc#16,0:"Element",1:"Text Node",2:"WhiteSpace",4:"Raw Text",3:"Next Node",:"Unknown")
			do outstream.Write(..#NewLine_..PadTxt(child,8)_..PadTxt(desc,12)_..PadTxt(desc\16,8)_..PadTxt(nodeType,12)_..PadTxt($E(..FormatText($G(xmlGbl(docId,"d",desc\16))),1,35),37))
    	}
	}
}

ClassMethod PadTxt(val, pad) [ CodeMode = expression, Internal ]
{
$E(..#pad,1,pad-$L(val))_val
}

/// Recursive output nodes
/// Repurpose of %XML.Writer method implementation for TreeInternal
ClassMethod TreeInternal(DocId, NodeId, baseChildlist, indent = -2, outstream As %Stream.Object) [ Internal, PublicList = (xmlGbl, %SAX) ]
{
    set tSC=$$$OK
    set localName=$$$xmlaGetLocalName(DocId,baseChildlist)
    set uri=$$$xmlaGetNamespaceURI(DocId,baseChildlist)
	
	do outstream.Write(..#NewLine_$E(..#pad,1,indent)_..#lblElement_":"_localName)
    set indent=indent+2

    // Start Region while loop for element attributes
    set row1=1
    $$$xmlaForEachAttribute(DocId,baseChildlist,o,attribute)
        Set attrname=$$$xmlaGetAttributeName(DocId,attribute)
		Set namespace=$$$xmlaGetAttrNamespaceURI(DocId,attribute)
		Set value=$$$xmlaGetAttribute(DocId,attribute)
		Set valueNamespace=$$$xmlaGetAttrValueNsURI(DocId,attribute)
		If (valueNamespace'="") && ($length(value,":")=2) {
			Set value=$piece(value,":",2)
		}
		do outstream.Write(..#NewLine_$E(..#pad,1,indent)_..#lblAttribute_":"_attrname_"="_..FormatText(value))
    $$$xmlaEndForEachAttribute(DocId,baseChildlist,o,attribute)
    /// End Region - while loop for element attributes

    Set parentNodeid=NodeId
	$$$xmlaFirstChild(DocId,parentNodeid,baseChildlist,NodeId,descriptor)
	While NodeId'="" {
		Set type=$$$xmlaGetNodeType(DocId,descriptor)
		If type=$$$xmlWHITESPACENODE {
			do outstream.Write(..#NewLine_$E(..#pad,1,indent)_..#lblWhiteSpaceNode_":")
			If '..#Indent {
				Set text=$$$xmlaGetData(DocId,descriptor)
				// Retain as-is internal content. Do not apply zcvt(text,"O","XMLC",overflow)
				do outstream.Write(..FormatText(text))
			} Else {
				Set wsnodeid=NodeId
				Set wsdescriptor=descriptor
				For {
					$$$xmlaNextChild(DocId,parentNodeid,baseChildlist,NodeId,descriptor)
					If NodeId="" Quit
					Set type=$$$xmlaGetNodeType(DocId,descriptor)
					If type'=$$$xmlWHITESPACENODE Quit
				}
				If (type=$$$xmlTEXTNODE) || (type=$$$xmlRAWTEXTNODE) {
					Set NodeId=wsnodeid
					Set descriptor=wsdescriptor
					
					Do {
						Set text=$$$xmlaGetData(DocId,descriptor)
						// Retain as-is internal content. Do not apply zcvt(text,"O","XMLC",overflow)
                        do outstream.Write(..#NewLine_$E(..#pad,1,indent+2)_..#lblTextNode)
						do outstream.Write("(Size="_$L(text)_"):")
						do outstream.Write(..FormatText(text))
						If $$$xmlaGetNodeType(DocId,descriptor)=type Quit
						$$$xmlaNextChild(DocId,parentNodeid,baseChildlist,NodeId,descriptor)
					} While NodeId'=""
				} ElseIf type=$$$xmlELEMENTNODE {
					$$$xmlaGetChildListFromDescriptor(DocId,descriptor,childlist)
					Set tSC=..TreeInternal(DocId,NodeId,childlist,indent+2,outstream)
				} Else {
					Quit
				}
			}
		} ElseIf type=$$$xmlTEXTNODE {
			do outstream.Write(..#NewLine_$E(..#pad,1,indent)_..#lblTextNode)
			Set text=$$$xmlaGetData(DocId,descriptor)
			// Retain as-is internal content. Do not apply zcvt(text,"O","XMLC",overflow)
			do outstream.Write("(Size="_$L(text)_"):")
			do outstream.Write(..FormatText(text))
		} ElseIf type=$$$xmlELEMENTNODE {
			$$$xmlaGetChildListFromDescriptor(DocId,descriptor,childlist)
			Set sc=..TreeInternal(DocId,NodeId,childlist,indent+2,outstream)
		} ElseIf type=$$$xmlRAWTEXTNODE {
			do outstream.Write(..#NewLine_$E(..#pad,1,indent)_..#lblRAWNode_":(Size="_$L(text)_")"_..FormatText($$$xmlaGetData(DocId,descriptor)))
		}
		quit:$$$ISERR(tSC)
		$$$xmlaNextChild(DocId,parentNodeid,baseChildlist,NodeId,descriptor)
	}
    Quit tSC
}

/// Covert non-printable and formating whitespace into ZWRITE style format<br/>
/// Allows some visibility and understanding of non-printing and formatting characters
/// <table>
/// <tr><th>Constant Value</th><th>Prints as</th></tr>
/// <tr><td>"ABC"</td><td>"ABC"</td></tr>
/// <tr><td>$C(10,13)_"ABC"</td><td>$C(10,13)_"ABC"</td></tr>
/// <tr><td>"DEF"_$C(10,13)_"ABC"</td><td>"DEF"_$C(10,13)_"ABC"</td></tr>
/// <tr><td>"DEF"_$C(1,2,3)_"G"_$C(4,5,6,7,8,9)_"ABC"</td><td>"DEF"_$C(1,2,3)_"G"_$C(4,5,6,7,8,9)_"ABC"</td></tr>
/// </table>
ClassMethod FormatText(data, empty = "<<EMPTY STRING>>") [ Internal ]
{
	if $L(data)=0 quit empty
	// Leading quote when first character is printable
	set out=$S($A($E(data,1))<32:"",1:"""")
	set len=$L(data),inNonPrinting=0
	for i=1:1:len {
		set char=$E(data,i)
		set achar=$A(char)
		if achar<32 {
			if 'inNonPrinting {
				// if first character is non printing then output starts with: $C(n,...
				// if first character is non printing then is continuation with: "_$C(n,...
				set out=out_$S(i>1:"""_$C(",1:"$C(")_achar
				set inNonPrinting=1
			} else {
				set out=out_","_achar
			}
		} else {
			if inNonPrinting {
				set out=out_")_"""
				set inNonPrinting=0
			}
			if char="""" {
				set out=out_""""""
			} else {
				set out=out_char
			}
		}	
	}
	if inNonPrinting {
		set out=out_")"
	} else {
		set out=out_""""
	}
	quit out
}

/// For a given filepath
/// Read in file as XML and output the corresponding SAX Tree structure
/// Parameters:<br/>
/// <ul>
/// <li><var>inputFilePath</var> - Required. The name of a local file containing XML.</li>
/// <li><var>outputFilePath</var> - Optional. The name of a local file containing XML.</li>
/// <li><var>dumpBinary</var> - Optional. To include additional and alternative view of content.</li>
/// </ul>
/// Example to explore an XML file and print output to default device
/// <example>
/// set tSC=##class(%XML.Utils.InspectSAXTree).ParseFile(inputFilePath)
/// do $SYSTEM.Status.DisplayError(tSC)
/// </example>
/// Example to explore an XML file and print output report to file.
/// <example>
/// set tSC=##class(%XML.Utils.InspectSAXTree).ParseFile(inputFilePath,outputFilePath)
/// do $SYSTEM.Status.DisplayError(tSC)
/// </example>
ClassMethod ParseFile(inputFilePath As %String, outputFilePath As %String = "", dumpBinary = 0) As %Status
{
    #dim outstream as %Stream.FileBinary=$$$NULLOREF
	if '##class(%File).Exists(inputFilePath) {
		quit $$$ERROR(5001,"Input File not found at "_inputFilePath)
	}
	set tSC=$$$OK

    if outputFilePath'="" {
        set saveOutput=1
        set outstream=##class(%Stream.FileBinary).%New("NWS")
        // If the directory doesn't exist will return error
        set tSC=outstream.LinkToFile(outputFilePath)
        quit:$$$ISERR(tSC) tSC
    } else {
        set saveOutput=0
    }

	#dim reader as %XML.Reader = ##class(%XML.Reader).%New()
    do reader.OpenFile(inputFilePath)

    do ..OutputTree(,,,.outstream,dumpBinary)
    do:saveOutput outstream.%Save()
	quit tSC
}

/// For a given string containing XML.
/// Read in XML and output the corresponding SAX Tree structure
/// Parameters:<br/>
/// <ul>
/// <li><var>xmlString</var> - Required. String containing well formed XML data.</li>
/// <li><var>outputFilePath</var> - Optional. The name of a local file containing XML.</li>
/// <li><var>dumpBinary</var> - Optional. To include additional and alternative view of content.</li>
/// </ul>
/// Example to explore a string  of XML content and print output to default device
/// <example>
/// set myxmlstring="<root><test>some data</test></root"
/// set tSC=##class(%XML.Utils.InspectSAXTree).ParseString(myxmlstring)
/// do $SYSTEM.Status.DisplayError(tSC)
/// </example>
/// Example to explore a string  of XML content and print output report to file.
/// <example>
/// set tSC=##class(%XML.Utils.InspectSAXTree).ParseStream(myxmlstream,outputFilePath)
/// do $SYSTEM.Status.DisplayError(tSC)
/// </example>
ClassMethod ParseString(xmlString As %String = "", outputFilePath As %String = "", dumpBinary As %Boolean = 0) As %Status
{
    if $L(xmlString)=0 {
        quit:$$$ERROR(5001,"Input XML string is empty")
    }

    if outputFilePath'="" {
        set saveOutput=1
        set outstream=##class(%Stream.FileBinary).%New("NWS")
        // If the directory doesn't exist will return error
        set tSC=outstream.LinkToFile(outputFilePath)
        quit:$$$ISERR(tSC) tSC
    } else {
        set saveOutput=0
    }

	#dim reader as %XML.Reader = ##class(%XML.Reader).%New()
    set tSC=reader.OpenString(xmlString)
    quit:$$$ISERR(tSC) tSC

    do ..OutputTree(,,,.outstream,dumpBinary)
    do:saveOutput outstream.%Save()
	quit $$$OK
}

/// For a given stream containing XML.
/// Read in XML and output the corresponding SAX Tree structure
/// Parameters:<br/>
/// <ul>
/// <li><var>xmlstream</var> - Required. Stream containing well formed XML data.</li>
/// <li><var>outputFilePath</var> - Optional. The name of a local file containing XML.</li>
/// <li><var>dumpBinary</var> - Optional. To include additional and alternative view of content.</li>
/// </ul>
/// Example to explore a stream  of XML content and print output to default device
/// <example>
/// set tSC=##class(%XML.Utils.InspectSAXTree).ParseStream(myxmlstream)
/// do $SYSTEM.Status.DisplayError(tSC)
/// </example>
/// Example to explore an XData block and print output report to file.
/// <example>
/// set tSC=##class(%XML.Utils.InspectSAXTree).ParseStream(myxmlstream,outputFilePath)
/// do $SYSTEM.Status.DisplayError(tSC)
/// </example>
ClassMethod ParseStream(xmlstream, outputFilePath As %String = "", dumpBinary As %Boolean = 0) As %Status
{
    if outputFilePath'="" {
        set saveOutput=1
        set outstream=##class(%Stream.FileBinary).%New("NWS")
        // If the directory doesn't exist will return error
        set tSC=outstream.LinkToFile(outputFilePath)
        quit:$$$ISERR(tSC) tSC
    } else {
        set saveOutput=0
    }

    #dim reader as %XML.Reader = ##class(%XML.Reader).%New()
    set tSC=reader.OpenStream(xmlstream)
    quit:$$$ISERR(tSC) tSC

    do ..OutputTree(,,,.outstream,dumpBinary)
    do:saveOutput outstream.%Save()
	quit $$$OK
}

/// For a given Class XData Block.
/// Read in XData content as XML and output the corresponding SAX Tree structure
/// Parameters:<br/>
/// <ul>
/// <li><var>xdataclass</var> - Required. Compiled classname with XData to review.</li>
/// <li><var>xdataname</var> - Required. The name of XData block to review.</li>
/// <li><var>outputFilePath</var> - Optional. The name of a local file containing XML.</li>
/// <li><var>dumpBinary</var> - Optional. To include additional and alternative view of content.</li>
/// </ul>
/// Example to explore an XData block and print output to default device
/// <example>
/// set tSC=##class(%XML.Utils.InspectSAXTree).ParseXData(myclassname,xdataname)
/// do $SYSTEM.Status.DisplayError(tSC)
/// </example>
/// Example to explore an XData block and print output report to file.
/// <example>
/// set tSC=##class(%XML.Utils.InspectSAXTree).ParseXData(myclassname,xdataname,outputFilePath)
/// do $SYSTEM.Status.DisplayError(tSC)
/// </example>
ClassMethod ParseXData(xdataclass = "", xdataname = "", outputFilePath As %String = "", dumpBinary As %Boolean = 0) As %Status
{
    if xdataclass="" {
        quit $$$ERROR(5001,"Parameter xdataclass not supplied")
    }
    if xdataname="" {
        quit $$$ERROR(5001,"Parameter xdataname not supplied")
    }
    if '##class(%Dictionary.CompiledXData).%ExistsId(xdataclass_"||"_xdataname) {
        quit $$$ERROR(5001,"XData "_xdataname_" not found in class "_xdataclass)
    }

    #dim xdata as %Dictionary.CompiledXData = ##class(%Dictionary.CompiledXData).%OpenId(xdataclass_"||"_xdataname)
    #dim xstream as %Stream.TmpCharacter = xdata.Data

    set tSC=..ParseStream(xstream,outputFilePath,dumpBinary)

	quit $$$OK
}

}
