/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Base class to allow schema extension
Class EnsLib.ebXML.schema.msg.base Extends (%SerialObject, %XML.Adaptor) [ Abstract, ClassType = serial, Inheritance = right, ProcedureBlock, System = 4 ]
{

Storage Default
{
<StreamLocation>^EnsLib.ebXML.schema.msg.baseS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
