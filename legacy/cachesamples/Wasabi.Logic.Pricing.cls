Include %occInclude

Class Wasabi.Logic.Pricing [ Abstract ]
{

/// Return price of a given item given a PriceCatalog
ClassMethod LookupPrice(catalog As Wasabi.Data.PriceCatalog, product As Wasabi.Data.Product) As %Float
{
	set catalogitem=##class(Wasabi.Data.PriceCatalogItem).ProductIndexOpen(catalog.%Id(),product.%Id(),,.sc)
	if $$$ISERR(sc) $$$ThrowStatus(sc)
	quit catalogitem.Price
}

}

