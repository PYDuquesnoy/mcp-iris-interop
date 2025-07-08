/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <class>%Library.Embedding</class> datatype is a subclass of <class>%Library.Vector</class> with <var>DATATYPE</var>="DOUBLE"
///  
/// <p>The value stored in this property is a $vector.  The IRIS engine keeps this embedding updated based on '<var>SOURCE</var>' properties as these source property items are modified. 
/// The property value will be computed/recompiled when the record is saved as needed.
///  
/// <p><class>%Library.Embedding</class> has the following property parameters:
/// <dl>
///     <dd><var>MODEL</var>  - Name of the embedding endpoint to use to construct embedding from the embedding endpoints table
/// <br><br>
///     <dd><var>SOURCE</var> - Comma separated list of property names of other properties in this class which are used as the source values for calculating the embedding. 
///               Names can be quoted with ' character to handle cases where referenced property name contains ',' characters. 
///               If a property referenced in this list does not exist it will throw a compile-time error. 
///               Wild card '*' indicator is supported and any name prefixed by '-' will remove this specific property from the list.
/// </dl> 
/// <p>The <var>LEN</var> property parameter will be read from the <var>MODEL</var> embedding endpoint table and inserted as a property parameter automatically, so the user does not need to specify this explicitly. 
/// This means the <var>LEN</var> becomes fixed at compile-time based on the endpoint table value for length.
///  
/// <p>If none of the <var>SOURCE</var> properties are modified, and this is an update to an existing %Persistent instance we will not recompile the embedding value when this instance is saved.
///  
/// <p>When a new embedding needs to be computed, a dynamic object based on the <var>SOURCE</var> properties will be constructued with the key being the property name and the value being the data value 
/// that is passed to the endpoint interfaces 'Embedding' or 'EmbeddingList' along with the <var>MODEL</var> endpoint name and the configuration information read from the endpoint table.
///  
/// <p>Example:<br><br>
///     <code>property MyEmbed as %Embedding(MODEL='text-embedding-3-small', SOURCE='Description,Name');</code>
///  
/// <p>This definition generates ComputeOnChange logic for <property>Description</property> and <property>Name</property> properties of this class to update this property by calling the 'Embedding' method of the endpoint interface class when either of these change. 
/// It stores a single embedding value for the description, name no matter how long these fields are. 
/// To handle multiple embeddings, we also support the 'list of' collection syntax:<br><br>
///     <code>property MyEmbed as List Of %Embedding(MODEL='text-embedding-3-small', SOURCE='Description,Name');</code>
///  
/// <p>This calls the 'EmbeddingList' method of the endpoint interface class and stores the list of embeddings that are returned. 
/// This list collection will be projected to SQL as a child table to allow JOIN queries between the embeddings and the parent table.
/// 
Class %Library.Embedding Extends %Library.Vector
{

/// Name of embedding endpoint to use to construct embedding from the embedding endpoints table
Parameter MODEL As STRING;

/// Comma separated list of property names of other properties in this class which are used as the source values for calculating the embedding. 
/// Names can be quoted with ' character to handle case where referenced property name contains ',' characters. 
/// If a property referenced in this list does not exist it will throw a compile time error. 
/// Wild card '*' indicator is supported and any name prefixed by '-' will remove this specific property from the list.
Parameter SOURCE As STRING;

}
