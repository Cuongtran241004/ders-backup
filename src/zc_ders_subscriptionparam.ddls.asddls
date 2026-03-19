//=============================================================================
// CDS VIEW: ZC_DERS_SubscriptionParam
// TYPE: Projection View (Consumption)
// PURPOSE: UI projection for subscription parameter values (child entity)
// PARENT: ZC_DERS_Subscription
//=============================================================================
@EndUserText.label: 'Subscription Parameter - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true

@Search.searchable: true

define view entity ZC_DERS_SubscriptionParam
  as projection on ZI_DERS_SubscriptionParam
{
      // ═══════════════════════════════════════════════════════════════
      // Key Fields
      // ═══════════════════════════════════════════════════════════════
      @UI.hidden: true
  key SubscrUuid,
  
      @UI.lineItem: [{ position: 10, importance: #HIGH }]
      @EndUserText.label: 'Sequence'
  key ParamSeq,
  
      // ═══════════════════════════════════════════════════════════════
      // Parameter Definition
      // ═══════════════════════════════════════════════════════════════
      @UI.lineItem: [{ position: 20, importance: #HIGH }]
      @EndUserText.label: 'Parameter Name'
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      ParamName,
      
      @UI.lineItem: [{ position: 30, importance: #HIGH }]
      @EndUserText.label: 'Value'
      ParamValue,
      
      @UI.lineItem: [{ position: 40, importance: #MEDIUM }]
      @EndUserText.label: 'From Value'
      ParamValueFrom,
      
      @UI.lineItem: [{ position: 50, importance: #MEDIUM }]
      @EndUserText.label: 'To Value'
      ParamValueTo,
      
      // ═══════════════════════════════════════════════════════════════
      // Metadata (from ZDERS_PARAM template)
      // ═══════════════════════════════════════════════════════════════
      @UI.lineItem: [{ position: 60, importance: #LOW }]
      @EndUserText.label: 'Data Element'
      DataElement,
      
      @UI.lineItem: [{ position: 70, importance: #MEDIUM }]
      @EndUserText.label: 'Mandatory'
      IsMandatory,
      
      @UI.lineItem: [{ position: 80, importance: #LOW }]
      @EndUserText.label: 'Default Value'
      DefaultValue,
      
      // ═══════════════════════════════════════════════════════════════
      // Virtual Fields (from Interface CDS)
      // ═══════════════════════════════════════════════════════════════
      @UI.hidden: true
      ParamTypeText,
      
      @UI.hidden: true
      EffectiveValue,
      
      // ═══════════════════════════════════════════════════════════════
      // Administrative Data
      // ═══════════════════════════════════════════════════════════════
      @UI.hidden: true
      CreatedBy,
      
      @UI.hidden: true
      CreatedAt,
      
      @UI.hidden: true
      LastChangedBy,
      
      @UI.hidden: true
      LastChangedAt,
      
      @UI.hidden: true
      LocalLastChangedAt,
      
      // ═══════════════════════════════════════════════════════════════
      // Association to Parent
      // ═══════════════════════════════════════════════════════════════
      _Subscription : redirected to parent ZC_DERS_Subscription
}
