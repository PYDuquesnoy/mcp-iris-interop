/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>The InterSystems IRIS NLP iKnow technology on which this index type is based is now deprecated. Please see the 
/// <a href="https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GIKNOW">product 
/// documentation</a> for more detail. The <class>%iKnow.Index.Basic</class> and <class>%iKnow.Index.Minimal</class>
/// index types remain fully supported.</p>
/// <p>This index class is a more advanced version of <class>%iFind.Index.Basic</class>, leveraging
/// the semantic output of the iKnow engine processing the text being indexed. In addition to the
/// search options provided by the Basic index, users can now also query for entities and their
/// attributes:</p>
/// <table class="DetailTable" cellpadding="0" cellspacing="0">
/// <tr><th width="250">Search string</th><th>What will be retrieved</th></tr>
/// <tr><td width="250">logical structure</td><td>All records containing both the words "logical" and "structure" (implicit AND)</td></tr>
/// <tr><td width="250">"logical structure"</td><td>All records containing the word "structure" right behind "logical" (positional search)</td></tr>
/// <tr><td width="250">{logical structure}</td><td>Records containing the actual <i>entity</i> "logical structure"</td></tr>
/// <tr><td width="250">&lt;{logical structure}</td><td>Expanded entity search for entities ending with "logical structure" (but something before too) </td></tr>
/// <tr><td width="250">{logical structure}&gt;</td><td>Expanded entity search for entities starting with "logical structure" (but something after too) </td></tr>
/// <tr><td width="250">&lt;logical structure</td><td>Implicit AND of entity search on entities ending with "logical" and simple word search on "structure"</td></tr>
/// <tr><td width="250">&lt;structure</td><td>Records containing entities ending with the word "structure"</td></tr>
/// <tr><td width="250">&lt;structure*</td><td>Records containing entities ending with any word beginning with "structure"</td></tr>
/// <tr><td width="250">&lt;structure AND NOT "logical structure"</td><td>Records containing entities ending with the word "structure", except if they also contain the exact string "logical structure" (positional search)</td></tr>
/// </table>
/// <p>Note: In the above table, the first two examples are also supported using a Basic index, but are
/// repeated here for comparison with the new entity search options.</p>
/// 
/// <p>If the <parameter>IFINDMAPPINGS</parameter> index is set to 1, the following additional SQL projections
/// will be generated:</p>
/// <ul>
/// <li><b>[<i>class_name</i>]_[<i>index_name</i>]_Ent</b>: stores which entities occur in which records. 
/// See also <class>%iFind.Index.AbstractEntity</class>.</li>
/// <li><b>[<i>class_name</i>]_[<i>index_name</i>]_EntSpread</b>: stores the total number of records in
/// which each entity occurs. See also <class>%iFind.Index.AbstractEntSpread</class>.</li>
/// </ul>
/// 
/// <p>For a detailed description of the other configuration and query options, see the class reference
/// for <class>%iFind.Index.Basic</class>.</p>
Class %iFind.Index.Semantic Extends %iFind.Index.Basic [ Deprecated, EmbeddedClass = %iFind.Find.Semantic, System = 2 ]
{

Parameter FILER [ Internal ] = "%iFind.Filer.Semantic";

/// <p>Whether or not to store attribute information, such as negation. 
/// If set to 1, the following additional projections will be generated in the "[<i>package_name</i>]_[<i>class_name</i>]" 
/// package if your <parameter>IFINDMAPPINGS</parameter> is set to 1, exposing attribute occurrence details:</p>
/// <ul>
/// <li><b>[<i>class_name</i>]_[<i>index_name</i>]_Attribute</b> stores whether a particular attribute 
/// occurs anywhere in a record. See also <class>%iFind.Index.AbstractAttribute</class>.</li>
/// <li><b>[<i>class_name</i>]_[<i>index_name</i>]_AttributePos</b> stores for a particular attribute, to
/// which word positions in the record it applies. See also <class>%iFind.Index.AbstractAttributePos</class>.</li>
/// </ul>
/// <p>The attribute values currently supported out of the box are:</p>
/// <ul>
/// <li>1: explicit negation within the entity</li>
/// <li>-1: negation implied by another entity within the path</li>
/// </ul>
Parameter IFINDATTRIBUTES As BOOLEAN = 0;

}
