/// <p>This class defines the domain shape and contents for the News Aggregator demo/tutorial.
/// To build the domain, set the disabled property of the root &lt;domain&gt; element to "false",
/// compile this class and run the <method>%Build</method> method.</p>
/// <p>See also <class>News.NewsReader</class>.</p>
/// 
/// <p>Note: you can add more RSS feeds to the definition below by duplicating an &lt;rss&gt;
/// element and modifying its attributes to select the news feed of your choice.</p>
Class News.NewsDomain Extends %iKnow.DomainDefinition
{

XData Domain [ XMLNamespace = "http://www.intersystems.com/iknow" ]
{
<domain name="News Aggregator demo" allowCustomUpdates="true" disabled="true" >

<configuration name="News Aggregator demo.Configuration" detectLanguage="true" languages="en,de,es,fr,nl,pt" />
<parameter name="DefaultConfig" value="News Aggregator demo.Configuration" />

<metadata>
<field name="PubDate" dataType="DATE" />
<field name="Title" dataType="STRING" />
<field name="Link" dataType="STRING" />
<field name="Agency" dataType="STRING" />
<field name="Country" dataType="STRING" />
</metadata>

<data dropBeforeBuild="true" >

<rss serverName="feeds.bbci.co.uk" url="/news/world/rss.xml" textElements="title,description" >
<converter converterClass="%iKnow.Source.Converter.Html" />
<metadataValue field="Agency" value="BBC" />
<metadataValue field="Country" value="UK" />
</rss>

<rss serverName="lemonde.fr" url="/rss/tag/international.xml" textElements="title,description" >
<converter converterClass="%iKnow.Source.Converter.Html" />
<metadataValue field="Agency" value="Le Monde" />
<metadataValue field="Country" value="France" />
</rss>

<rss serverName="spiegel.de" url="/politik/ausland/index.rss" textElements="title,description" >
<converter converterClass="%iKnow.Source.Converter.Html" />
<metadataValue field="Agency" value="Der Spiegel" />
<metadataValue field="Country" value="Germany" />
</rss>

<rss serverName="ep00.epimg.net" url="/rss/internacional/portada.xml" textElements="description,content:encoded" >
<converter converterClass="%iKnow.Source.Converter.Html" />
<metadataValue field="Agency" value="El País" />
<metadataValue field="Country" value="Spain" />
</rss>

<rss serverName="rss.cnn.com" url="/rss/edition.rss" textElements="title,description" >
<converter converterClass="%iKnow.Source.Converter.Html" />
<metadataValue field="Agency" value="CNN" />
<metadataValue field="Country" value="USA" />
</rss>

<rss serverName="rss.cnn.com" url="/rss/edition_world.rss" textElements="title,description" >
<converter converterClass="%iKnow.Source.Converter.Html" />
<metadataValue field="Agency" value="CNN" />
<metadataValue field="Country" value="USA" />
</rss>

<!--
<rss serverName="feeds.folha.uol.com.br" url="/mundo/rss091.xml" textElements="title,description" >
<converter converterClass="%iKnow.Source.Converter.Html" />
<metadataValue field="Agency" value="Folha de Sao Paolo" />
<metadataValue field="Country" value="Brazil" />
</rss>

<rss serverName="www.df.cl" url="/prontus_df/site/edic/base/rss/inicio.xml" textElements="title,description" >
<converter converterClass="%iKnow.Source.Converter.Html" />
<metadataValue field="Agency" value="Diario Financiero" />
<metadataValue field="Country" value="Chile" />
</rss>
-->

</data>

<matching>
<dictionary name="International">
<item name="USA" uri=":international:usa" >
<term string="USA" />
<term string="US" />
<term string="United States" />
<term string="EEUU" />
</item>
<item name="UK" uri=":international:uk" >
<term string="UK" />
<term string="United Kingdom" />
</item>
<item name="Europe" uri=":international:europe" >
<term string="Europe" />
<term string="EU" />
<term string="European Union" />
</item>
<item name="Belgium" uri=":international:belgium" >
<term string="Belgium" />
<term string="Belgique" />
</item>
<item name="Germany" uri=":international:germany" >
<term string="Germany" />
<term string="Deutschland" />
</item>
<item name="France" uri=":international:france" >
<term string="France" />
</item>
<item name="Spain" uri=":international:spain" >
<term string="Spain" />
<term string="España" />
</item>
<item name="Brazil" uri=":international:brazil" >
<term string="Brazil" />
<term string="Brasil" />
</item>
<item name="Chile" uri=":international:chile" >
<term string="Chile" />
</item>
<item name="China" uri=":international:china" >
<term string="China" />
<term string="Chinese" />
</item>
<item name="Russia" uri=":international:russia" >
<term string="Russia" />
</item>
<item name="Japan" uri=":international:japan" >
<term string="Japan" />
<term string="Japanese" />
</item>
</dictionary>
<dictionary name="Sports">
<item name="Soccer" uri=":sports:soccer">
<term string="soccer" />
<term string="football" />
</item>
<item name="Cycling" uri=":sports:cycling">
<term string="cycling" />
<term string="bike" />
<term string="biking" />
</item>
<item name="Baseball" uri=":sports:baseball">
<term string="baseball" />
<term string="bat" />
<term string="honk" />
</item>
</dictionary>
<dictionary name="Entertainment">
<item name="Cinema" uri=":entertainment:cinema">
<term string="cinema" />
<term string="film" />
<term string="movie" />
</item>
<item name="Music" uri=":entertainment:music">
<term string="music" />
<term string="album" />
<term string="band" />
</item>
</dictionary>
</matching>
</domain>
}

/// Populates a complementary table for the iFind search option in the NewsReader class
ClassMethod %OnAfterBuild(pDomainId As %Integer) As %Status
{
	// call the CopyFromDomain() method to load the table
	quit ##class(News.Article).CopyFromDomain()
}

}

