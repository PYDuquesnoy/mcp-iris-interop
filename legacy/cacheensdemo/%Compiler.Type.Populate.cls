/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Property superclass used to hold information about how to populate this property.
Class %Compiler.Type.Populate [ System = 3 ]
{

/// POPSPEC defines a 'value generator method' for a property.
/// It is used by the %Populate class to generate sample data.
/// The format of POPSPEC is this <value generator>[:[<collection count>]:[<collection array key value generator>]].
Parameter POPSPEC;

/// POPORDER defines the order in which this property will be assigned a value. This should be an integer value.
/// If POPORDER is less than zero then the property will not be populated by the Populate method.
Parameter POPORDER;

}
