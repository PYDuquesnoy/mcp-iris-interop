Class News.Results.Sources Extends %Persistent [ StorageStrategy = CustomStorage ]
{

Property ResultId As %Numeric;

Property SourceId As %Integer;

Property ExternalId As %String(MAXLEN = 2000);

Index PKINDEX On ResultId [ IdKey, PrimaryKey, Unique ];

Storage CustomStorage
{
<CounterLocation>^News.Results.SourcesINC</CounterLocation>
<ExtentSize>100000</ExtentSize>
<SQLMap name="MainMap">
<Data name="ExternalId">
<Piece>2</Piece>
</Data>
<Data name="SourceId">
<Piece>1</Piece>
</Data>
<Global>^News.Results.Sources</Global>
<Subscript name="1">
<Expression>{ResultId}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^News.Results.SourcesS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}

