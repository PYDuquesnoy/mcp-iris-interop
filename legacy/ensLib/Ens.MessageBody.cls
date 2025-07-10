/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Base class for simple message classes, and for the sub- base classes Ens.Request and Ens.Response.
/// Note however that any persistent or serial object can be sent as a message body. It is not required that all message body
/// object classes to be derived from this class.  Also note that all message classes derived from this class will share the
/// same storage extent in the database.
Class Ens.MessageBody Extends (%Persistent, Ens.Util.MessageBodyMethods, %XML.Adaptor) [ System = 4 ]
{

/// Override DOMAIN inherited from %CSP.Util.AutoForm
Parameter DOMAIN;

Parameter EXTENTSIZE = 2000000;

Parameter XMLIGNORENULL = 1;

/// Prevent this class from having the same default XML Type and Name as any of its subclasses that have the short classname.
Parameter XMLTYPE As %String = "Ens_Messagebody";

/// Prevent the XML Type and Name of classes derived from this class from interfering with one another if they have the same short classname.
Parameter XMLINCLUDEINGROUP As %Boolean = 0;

Storage Default
{
<Data name="MessageBodyDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^Ens.MessageBodyD</DataLocation>
<DefaultData>MessageBodyDefaultData</DefaultData>
<ExtentSize>2000000</ExtentSize>
<IdLocation>^Ens.MessageBodyD</IdLocation>
<IndexLocation>^Ens.MessageBodyI</IndexLocation>
<StreamLocation>^Ens.MessageBodyS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
