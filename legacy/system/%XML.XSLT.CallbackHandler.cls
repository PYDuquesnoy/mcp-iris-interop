/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p><b>For details on using this class</b>, see
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25XML.XSLT.CallbackHandler">Performing XSLT Transformations</a>.</p>
/// This class handles callbacks from the XSLT processor. You should create a subclass this class and override the 
/// 'evaluate' method to perform the processing that you require. An example of an stylesheet using this function is
/// shown in the example XSL contained in the %XML.XSLT.Transformer class
Class %XML.XSLT.CallbackHandler Extends %RegisteredObject [ System = 3 ]
{

/// Evaluate receives a variable number of arguments, allowing you to pass multiple arguments on the evaluate
/// call. The number of arguments is available in the Args variable and each value can be accessed by subscripting.
/// The method has a single return value which will be returned as the result of the xslt evaluate function(). The return
/// value can either be a regular cache variable or it can be an instance of a stream object. This allows for returning a 
/// value that is greater than 32k in size. The stream has to be wrapped in an instance of %XML.XSLT.StreamAdapter which
/// facilitates the XSLT processors reading of the stream. This example shows both techniques, change the 1 to 0 to test
/// the stream functionality (%XML.XSLT.Transformer.Example3() exercises this functionality)
Method evaluate(Args...) As %String
{
#if 1
	Quit $Reverse(Args(1))
#else
	Set tStream=##class(%GlobalCharacterStream).%New()
	Do tStream.Write($Reverse(Args(1)))
	Quit ##class(%XML.XSLT.StreamAdapter).%New(tStream)
#endif
}

}
