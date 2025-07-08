/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is the interface class for xDBC STRUCT objects. Values are expected to be orefs.
Class %Library.IStruct Extends %SerialObject [ ClientDataType = HANDLE, ClientName = SerialObject, OdbcType = STRUCT, System = 2 ]
{

Storage Default
{
<StreamLocation>^%Library.IStructS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
