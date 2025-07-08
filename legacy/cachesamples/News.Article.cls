/// Utility class to demonstrate iFind search capabilities with the News Aggregator demo.
/// For licensing reasons, the index is only created when <method>CopyFromDomain</method> is
/// invoked for the first time, as an iKnow license might not be available on the system.
/// See also the RefreshTable() method in the <class>News.NewsReader</class> class on how to 
/// query this index.
Class News.Article Extends %Persistent
{

Property Agency As %String(MAXLEN = 100);

Property Article As %String(MAXLEN = "");

Property PubDate As %DeepSee.Datatype.dateTime;

Property SourceId As %Integer;

Property ExternalId As %String(MAXLEN = 500);

/// Populates this table based on the data in the domain managed by <class>News.NewsDomain</class>
ClassMethod CopyFromDomain() As %Status
{
	set tSC = $$$OK
	try {
		// first ensure this table contains an iFind index.
		// We'll only generate this now to ensure there is an appropriate iKnow license for this system
		if '##class(%Dictionary.CompiledIndex).%ExistsId("News.Article||TxtIdx") {
			// Index TxtIdx On (Article) As %iFind.Index.Semantic(INDEXOPTION = 0, LANGUAGE = "*");
			set tIndex = ##class(%Dictionary.IndexDefinition).%New()
			set tIndex.Name = "TxtIdx"
			set tIndex.Properties = "Article"
			set tIndex.TypeClass = "%iFind.Index.Semantic"
			do tIndex.Parameters.SetAt("*", "LANGUAGE")
			set tClass = ##class(%Dictionary.ClassDefinition).%OpenId("News.Article")
			do tClass.Indices.Insert(tIndex)
			set tSC = tClass.%Save()
			quit:$$$ISERR(tSC)
			set (tClass,tIndex) = ""
			set tSC = $system.OBJ.Compile("News.Article", "-d")
			quit:$$$ISERR(tSC)
		}
		
		// erase any existing data
		set tSC = ..%DeleteExtent()
		quit:$$$ISERR(tSC)
		
		
		// retrieve the domain ID and relevant metadata field IDs
		set tDomainId = ##class(News.NewsDomain).%GetDomainId()
		set tPubDateField = ##class(%iKnow.Queries.MetadataAPI).GetFieldId(tDomainId, "PubDate")
		set tAgencyField = ##class(%iKnow.Queries.MetadataAPI).GetFieldId(tDomainId, "Agency")
		
		
		// populate the table using a single INSERT statement
		set tSQL = "INSERT INTO News.Article (SourceId, ExternalId, Article, Agency, PubDate) "_
					" SELECT s.SourceId, s.ExternalId, s.FullText Article, m2.Value Agency, m1.Value PubDate "_
		//			" 	DATEADD('second', $PIECE(m1.Value,',',2), DATEADD('day', $PIECE(m1.Value,',',1), {ts '1840-12-31'})) PubDate"_
					" FROM %iKnow_Objects.Source s, %iKnow_Objects.MetadataValue m1, %iKnow_Objects.MetadataValue m2 "_
					" WHERE s.DomainId = ? AND s.DomainId = m1.DomainId AND s.DomainId = m2.DomainId "_
					"	AND s.SourceId = m1.SourceId AND s.SourceId = m2.SourceId" _
					" 	AND m1.FieldId = ? AND m2.FieldId = ? "
		set tStatement = ##class(%SQL.Statement).%New()
		set tSC = tStatement.%Prepare(tSQL)
		quit:$$$ISERR(tSC)
		
		kill %objlasterror
		do tStatement.%Execute(tDomainId, tPubDateField, tAgencyField)
		set tSC = $g(%objlasterror,$$$OK)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Storage Default
{
<Data name="ArticleDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Agency</Value>
</Value>
<Value name="3">
<Value>Article</Value>
</Value>
<Value name="4">
<Value>PubDate</Value>
</Value>
<Value name="5">
<Value>SourceId</Value>
</Value>
<Value name="6">
<Value>ExternalId</Value>
</Value>
</Data>
<DataLocation>^News.ArticleD</DataLocation>
<DefaultData>ArticleDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^News.ArticleD</IdLocation>
<IndexLocation>^News.ArticleI</IndexLocation>
<StreamLocation>^News.ArticleS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

