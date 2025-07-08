/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Net.Remote.Java.XSLTGatewayRequest Extends %RegisteredObject
{

Property RequestType As %Integer;

Property ErrorHandler As %XML.XSLT.ErrorHandler [ InitialExpression = {$$$NULLOREF} ];

Property CallbackHandler As %XML.XSLT.CallbackHandler [ InitialExpression = {$$$NULLOREF} ];

Property Parameters As %List [ InitialExpression = {$$$NULLOREF} ];

Property EntityResolver As %ObjectHandle [ InitialExpression = {$$$NULLOREF} ];

Property XMLFilePath As %String;

Property XSLTFilePath As %String;

Property XMLStream As %RawString;

Property XSLTStream As %RawString;

Property XMLString As %String;

Property CompiledStylesheet As %XML.XSLT2.CompiledStyleSheet [ InitialExpression = {$$$NULLOREF} ];

Property TargetFilePath As %String;

Property NewEvaluateCacheSize As %Integer [ InitialExpression = 0 ];

Property NewCacheEverythingBoolean As %Boolean [ InitialExpression = 0 ];

Property FilterListFunctionCall As %String;

Property FilterListArgs As %List [ InitialExpression = {$$$NULLOREF} ];

Property EvaluateCacheToLoad As %List [ InitialExpression = {$$$NULLOREF} ];

Property CompiledPackage As %XML.XSLT3.CompiledPackage [ InitialExpression = {$$$NULLOREF} ];

Property CompiledPackages As %List;

Property EnableStreaming As %Boolean [ InitialExpression = 0 ];

Property XSLTRequestType As %String;

Property CompiledXSLT3Stylesheet As %XML.XSLT3.CompiledStyleSheet [ InitialExpression = {$$$NULLOREF} ];

Property Options As %List [ InitialExpression = {$$$NULLOREF} ];

Property XMLBaseDir As %String;

Property XSLBaseDir As %String;

}
