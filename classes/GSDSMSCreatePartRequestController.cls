public class GSDSMSCreatePartRequestController {
    public string serialNo{get;set;}
    public string productNo{get;set;}
    public String requestLabel;
    public boolean flag{get;set;}
    public boolean popdisplay{set;get;}//To show popup after case record creation 
    public boolean isEntitlementSuccesful{get;set;}
    public Boolean productOffers{get;set;}
    public string endresult{set;get;}
    public string strCaseReferenceId {get;set;}
    public DateTime startTime;    
    public string PartNumber {get;set;}
    public Boolean displayPopup {get;set;}
    public string strAccountName {get;set;}
    public string strContactName {get;set;}
    public string strLocationName {get;set;}
    public GSDEntitlementServiceWrapper.GSDEntitlement entit;
    public AsyncGSDEntitlementServiceWrapper.GetEntitlementOffersUsingDataContractResponse_elementFuture answerProdResponse{get;set;}
    public GSDEntitlementServiceWrapper.GSDEntitlementSearchResult answerProd{get;set;}
    public GSDEntitlementServiceWrapper.GSDEntitlementSearchResult stdanswer{get;set;}
    public string isMdcp=string.valueof(GSDCSCChannelData__c.getvalues(GSDCSCConstants.ChannelRecord).IsCRSToMDCPEnabledstr__c);
    public string isSOLIDCall=string.valueof(GSDCSCServiceCallStatus__c.getvalues('isSOLIDCall').servicestatus__c);
    public string isESCall=string.valueof(GSDCSCServiceCallStatus__c.getvalues('isESCall').servicestatus__c);
    public string isSAPCall=string.valueof(GSDCSCServiceCallStatus__c.getvalues('isSAPCall').servicestatus__c);
    public string country='USA';
    public string CID{get; set;}
    public case gSDCase{get; set;}
    public integer offerListSize {get;set;}
    public User usr;
    public Contact CurrContact {get;set;}
    public string assetname {get;set;}
    public Asset CurrAsset {get;set;}
    public List<GSD_Service_Delivery_Location_Setting__c> lstSerDelSettings {get;set;}
    public AsyncGSDBomclass.SerializedProductAndSupportPartListFuture GetBOM;
    public GSDBomclass.SerializedProductAndSupportPartList output{get;set;}
    public list<compnentBOMItem> componentBOMList{get;set;} 
    MonitorUtility objmonitorutility=new MonitorUtility();
    public DateTime dtStartTime;
    public string partSurferUrl;
    public list<Wrapper> spareBomList{get;set;}
    public list<Wrapper> spareBomList_Secondary{get;set;}
    public list<Wrapper> main= new List<Wrapper>();
    public boolean assetNotPresentInSFDC {get;set;}
    public List<GSD_Service_Delivery_Location_Setting__c> lstLocationsForAccount;
    public Map<Id,GSD_Service_Delivery_Location_Setting__c> mapLocationIdWithSLDS;
    public List<Asset> lstAssets;
    public List<SelectOption> lstSelectOptions {get;set;}
    public string strSelectedLocationId {get;set;}  
    public string strsOOSType;
    public boolean IsMultiVendorProduct; 
    public string txtSearch {get;set;} 
                public Boolean isDuplicateAssetPresent {get;set;} 
    
    GSDEntitlementServiceWrapper.ArrayOfGSDOffer selectedGSDOffer ;
    public GSDSMSCreatePartRequestController()
    { 
        spareBomList = new list<Wrapper>();
        popdisplay=false;
        assetNotPresentInSFDC = true;
        serialNo=apexpages.currentpage().getParameters().get('serialNo');
        productNo=apexpages.currentpage().getparameters().get('productNo');
        lstAssets = new List<Asset>();
        lstSelectOptions = new List<SelectOption>();
        //partNumber='101920-001';
        //ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Error,'Product does not have valid entitlement, please contact HPE account manager'));
        //Get loggedin user contact and account              
        isEntitlementSuccesful = false;        
        List<Contact> lstContact = new List<contact>();
        User CurrentUser = [select Id, contactId from user where  Id=:userinfo.getUserId()];    //Id=:userinfo.getUserId()];        
        lstContact = [select id, firstname,Email,lastname, phone, AccountId, Account.Name from contact where id=:CurrentUser.ContactId];
        if(lstContact.size()>0)
            CurrContact = lstContact[0];
        //Get Locations for the account
        mapLocationIdWithSLDS = new Map<Id,GSD_Service_Delivery_Location_Setting__c>();
        lstLocationsForAccount = [select id,Delivery_Location__c,Delivery_Location__r.Name,Delivery_Location__r.City__c,Part_Pickup_Location__r.Location_Name__c from GSD_Service_Delivery_Location_Setting__c where Delivery_Location__r.account__c=:lstContact[0].AccountId and Dedicated_PPUL_supports_CSR__c=true and Part_Pickup_Location__c!=null];
        if(lstLocationsForAccount.size()>0)
        {
            for(GSD_Service_Delivery_Location_Setting__c currSLDS:lstLocationsForAccount)
                mapLocationIdWithSLDS.put(currSLDS.Delivery_Location__c,currSLDS);
        }
                                isDuplicateAssetPresent = false;
    }
    
    public void CreateAsset()
    {
        if(assetNotPresentInSFDC)
        {
                                                isDuplicateAssetPresent = false;
                                                List<Asset> lstDuplicateAsset = [SELECT Id FROM Asset where SerialNumber=:serialNo and HP_Product_Number__c=:productNo];
                                                if(lstDuplicateAsset.Size()>0)
                                                {
                                                                isDuplicateAssetPresent = true;
                                                                return;
                                                }
                                                
            Asset ObjNewAsset = new Asset();
            Product_Hierarchy__c prodHierarchy = new Product_Hierarchy__c();
            prodHierarchy = GSD_Product_Hierarchy_Helper.getProductDetail(productNo);
            if(prodHierarchy != null )
            {
                ObjNewAsset.Description  = prodHierarchy.pm_product_dn__c;
                ObjNewAsset.Product_Hierarchy__c = prodHierarchy.Id;
                if(prodHierarchy.PM_SUPPORT_MODEL_NM__c!=null&&prodHierarchy.PM_SUPPORT_MODEL_NM__c!=GSDCSCConstants.EmptyString)
                {
                    ObjNewAsset.Name = prodHierarchy.PM_SUPPORT_MODEL_NM__c;                              
                }
                    
            }                
            ObjNewAsset.Name = productNo;
            ObjNewAsset.HP_Asset_Type__c = 'Object of Service';
            ObjNewAsset.GSD_Is_Valid__c = true;
            ObjNewAsset.Location__c = strSelectedLocationId;
            ObjNewAsset.AccountId = CurrContact.AccountId;
            ObjNewAsset.HP_Product_Number__c = productNo;
            ObjNewAsset.SerialNumber = serialNo;
            ObjNewAsset.GSD_Validation_Source__c = 'OBS';
            ObjNewAsset.GSD_Validation_Date__c = DateTime.now();
            ObjNewAsset.GSD_Asset_Unique_Key__c = serialNo + '&' + productNo;
            ObjNewAsset.Asset_Domain__c = strsOOSType;
            ObjNewAsset.IsCompetitorProduct = IsMultiVendorProduct;        
           // User objUser = [select id from user where username like 'sms-app@hpe.com%'];
            //system.RunAs(objUser)
            //{
                insert ObjNewAsset;            
            //}
            lstAssets = [SELECT Name,HP_Product_Number__c,Location_Detail__c,Location__c,Location__r.Postal_Code__c,Location__r.name,Location__r.Street_Line_1__c,Location__r.Street_Line_2__c,Location__r.City__c,Location__r.State__c,Location__r.World_Region1__r.name,Location__r.street__C,SerialNumber FROM Asset where Id=:ObjNewAsset.Id and GSD_Is_Valid__c=true and HP_Asset_Type__c='Object of Service'];
            system.debug('Asset Created');
        }
    }

    public continuation getValidate() 
    {   
        if(string.isblank(serialNo)||string.isblank(productNo))
        {       /* serialNumber and product number validation */
            string errordisplay='';//To display error message.
            if(string.isblank(serialNo)){
                errordisplay+='Serial Number,';
            }
            if(string.isblank(productNo)){
                errordisplay+='Product Number';
            }
            ApexPages.addmessage(new Apexpages.Message(ApexPages.Severity.Error, system.label.GSD_SMS_RequiredFieldsMissingError+errordisplay.removeEnd(',')));
           
            return null;
        }
        else
        {     
            User CurrentUser = [select Id, AccountId,contactId from user where Id=:userinfo.getUserId() ];    //username='testsms@gmail.com']; 
            List<contact> lstContacts = new List<contact>();
            lstContacts = [select id, firstname, lastname, phone, AccountId, Account.Name from contact where id=:CurrentUser.ContactId];
            lstAssets = [SELECT Name,HP_Product_Number__c,Location_Detail__c,Location__c,Location__r.Postal_Code__c,Location__r.name,Location__r.Street_Line_1__c,Location__r.Street_Line_2__c,Location__r.City__c,Location__r.State__c,Location__r.World_Region1__r.name,Location__r.street__C,SerialNumber FROM Asset where HP_Product_Number__c=:productNo and SerialNumber=:serialNo and location__c!='' and location__r.account__r.id=:lstContacts[0].accountid and GSD_Is_Valid__c=true and HP_Asset_Type__c='Object of Service'];
            if(lstAssets.size()>0)            
                assetNotPresentInSFDC = false;
            
            /*else if(lstLocationsForAccount.size()==0)
            {
                ApexPages.addmessage(new Apexpages.Message(ApexPages.Severity.Error, 'Asset does not exist and No locations mapped to the account, please contact HPE account manager'));            
                return null;
            }*/

            if(lstContacts.size()>0)
            {
                strContactName = lstContacts[0].lastname;  
                strAccountName  = lstContacts[0].Account.Name; 
            }
            continuation continuationobject = new continuation(120);
            continuationobject.continuationMethod = 'getEntitlementCallback';
            answerProdResponse =  new AsyncGSDEntitlementServiceWrapper.GetEntitlementOffersUsingDataContractResponse_elementFuture();     
            
            AsyncGSDEntitlementServiceWrapper.AsyncGSDEntitlementServiceSOAPSoap wrapper = new AsyncGSDEntitlementServiceWrapper.AsyncGSDEntitlementServiceSOAPSoap();
            wrapper.clientCertName_x = GSDCSCConstants.Certificate;
            wrapper.timeout_x=120000;
            GSDEntitlementServiceWrapper.ArrayOfGSDOffer SelectedOffer=new GSDEntitlementServiceWrapper.ArrayOfGSDOffer();
            wrapper.endpoint_x = GSD_CSC_Webservice_Endpoint_URL__c.getValues(GSDCSCConstants.GSDSearch).Endpoint_URL__c;        
            answerProdResponse = wrapper.beginGetEntitlementOffersUsingDataContract(continuationobject, serialNo, 'US', productNo, GSDCSCConstants.EmptyString, GSDCSCConstants.EmptyString,'true', GSDCSCConstants.EmptyString, GSDCSCConstants.EmptyString, GSDCSCConstants.EmptyString, '345234', GSDCSCConstants.EmptyString, GSDCSCConstants.EmptyString,GSDCSCConstants.EmptyString,'0',SelectedOffer,'true','true','true','true');   
            system.debug('-->answ'+answerProdResponse);        
            return continuationobject;
        }
    }
    public Object getEntitlementCallback()
    {
        answerProd = answerProdResponse.getValue();
        system.debug('answerProd:'+answerProd);
        boolean doesSelectedOfferExists = false;    
        if(answerProd != null && answerProd.GSDEntitlementResult != null)
        {
            strsOOSType = answerProd.GSDEntitlementResult.sOOSType;
            IsMultiVendorProduct = answerProd.GSDEntitlementResult.IsMultiVendorProduct;
            system.debug('Response is not null');
            if(answerProd.GSDEntitlementResult.GSDOffers != null && answerProd.GSDEntitlementResult.GSDOffers.GSDOffer != null)
            {
                system.debug('Offers exist');
                for(GSDEntitlementServiceWrapper.GSDOffer offer: answerProd.GSDEntitlementResult.GSDOffers.GSDOffer)
                {   
                    if(offer.IsSelectedOffer)  
                    {                      
                        doesSelectedOfferExists = true;
                        break;
                    }
                }
                system.debug('doesSelectedOfferExists:'+doesSelectedOfferExists);
                if(doesSelectedOfferExists)
                {
                    // showSection= true;
                    isEntitlementSuccesful = true;
                    system.debug('Flag----'+flag);
                }
                else
                    isEntitlementSuccesful = false;
            }
            else
                isEntitlementSuccesful = false;
        }
        else
        { 
            //showSection= false;
            isEntitlementSuccesful = false;
            system.debug('Flag----'+flag);
        }        
        
        if(!isEntitlementSuccesful)
            ApexPages.addmessage(new Apexpages.Message(ApexPages.Severity.Error,system.label.GSD_SMS_EntitlementError));
        else
        {
            if(!assetNotPresentInSFDC)
            {
                if(mapLocationIdWithSLDS.get(lstAssets[0].Location__c)!=null)
                {
                    GSD_Service_Delivery_Location_Setting__c currSLDS = mapLocationIdWithSLDS.get(lstAssets[0].Location__c);                    
                    string strSiteLocation;
                    if(String.IsNotBlank(currSLDS.Part_Pickup_Location__r.Location_Name__c))
                    {
                        strSiteLocation = currSLDS.Part_Pickup_Location__r.Location_Name__c;
                        strSiteLocation = strSiteLocation.substring(0, 7);
                        strLocationName = currSLDS.Delivery_Location__r.Name + '/' + currSLDS.Delivery_Location__r.City__c + '/' + strSiteLocation;                                     
                    }
                    else
                    {
                        ApexPages.addmessage(new Apexpages.Message(ApexPages.Severity.Error,'Asset does not have a smart box mapped, please contact HPE Account Manager'));
                    }
                }
                else
                {
                    ApexPages.addmessage(new Apexpages.Message(ApexPages.Severity.Error,'Asset does not have a smart box mapped, please contact HPE Account Manager'));
                }
                assetname = lstAssets[0].name;
            }
            else
            {        
                lstSelectOptions.add(new SelectOption('None','None'));         
                for(GSD_Service_Delivery_Location_Setting__c ObjSLDS:lstLocationsForAccount)
                {
                    string strSiteLocation;
                    strSiteLocation = ObjSLDS.Part_Pickup_Location__r.Location_Name__c;
                    strSiteLocation = strSiteLocation.substring(0, 7);
                    strSiteLocation = ObjSLDS.Delivery_Location__r.Name + '/' + ObjSLDS.Delivery_Location__r.City__c + '/' + strSiteLocation;
                    lstSelectOptions.add(new SelectOption(ObjSLDS.Delivery_Location__c,strSiteLocation));              
                }
            }
            
            /*List<asset> lstAsset = [select id,name,Location__c,Location__r.World_Region1__r.name,Location__r.Street_Line_1__c,Location__r.Street_Line_2__c,Location__r.City__c,Location__r.State__c,Location__r.Postal_Code__c from asset where Serialnumber=:serialNo and HP_Product_Number__c=:productNo];            
            if(lstAsset.size()>0)
            {
                CurrAsset = lstAsset[0];
                if(string.IsNotBlank(CurrAsset.Location__c))
                {
                    lstSerDelSettings = [select id,Part_Pickup_Location__c,Part_Pickup_Location__r.Location_Name__c,Dedicated_PPUL_supports_CSR__c from GSD_Service_Delivery_Location_Setting__c where Delivery_Location__c=:CurrAsset.Location__c];
                    if(lstSerDelSettings.size()>0)
                    {
                        strLocationName = lstSerDelSettings[0].Part_Pickup_Location__r.Location_Name__c;
                        strLocationName = strLocationName.substring(0, 7);
                    }
                }
                assetname = lstAsset[0].name;
            }*/
        }
        
        return null;
    }
    
    public void Submit()
    { 
        if(string.isblank(strCaseReferenceId)||string.isblank(PartNumber) || ((string.isblank(strSelectedLocationId) || strSelectedLocationId.EqualsIgnoreCase('None')) && string.isblank(strLocationName)))
        { /*CaseReferenceId and PartNumber validation*/
            string errordisplay='';
            Boolean displayError = false;
            if(string.isblank(strCaseReferenceId)){
                displayError = true;
                errordisplay+='Customer Reference Id,';
            }
            if(string.isblank(PartNumber)){
                displayError = true;
                errordisplay+='PartNumber,';
            }
            if((string.isblank(strSelectedLocationId) || strSelectedLocationId.EqualsIgnoreCase('None')) && string.isblank(strLocationName))
            {
                displayError = true;
                errordisplay+='Location';
            }
            if(string.IsNotBlank(errordisplay))
                errordisplay = errordisplay.removeEnd(',');
            if(displayError)
                ApexPages.addmessage(new Apexpages.Message(ApexPages.Severity.Error,system.label.GSD_SMS_RequiredFieldsMissingError+errordisplay));
        }
        else if(isDuplicateAssetPresent)
        {
                        ApexPages.addmessage(new Apexpages.Message(ApexPages.Severity.Error,'Asset is mapped to a different account, please contact HPE Account Manager'));
        }
        else
        {
            try
            {
                list<GSD_SMS_Case_Default_Values__mdt> mdts= new list<GSD_SMS_Case_Default_Values__mdt>();
                mdts=[select DeafaultValue__c,Label from GSD_SMS_Case_Default_Values__mdt];
                map<string,string> maps=new map<string,string>();
                for(GSD_SMS_Case_Default_Values__mdt n:mdts)
                {
                    maps.put(n.label,n.DeafaultValue__c);
                }
                
                GSDSMSCreateCase ObjGSDSMSCreateCase = new GSDSMSCreateCase();
                GSDSMSCreateCase.Notification ObjNotification = new GSDSMSCreateCase.Notification();                            
                GSDSMSCreateCase.GSD_SMS_Bulk_Part_Request_xc ObjRequest = new GSDSMSCreateCase.GSD_SMS_Bulk_Part_Request_xc();
                GSDSMSCreateCase.GSD_SMS_Bulk_Part_Request_xcNotification ObjRequestParam = new GSDSMSCreateCase.GSD_SMS_Bulk_Part_Request_xcNotification();
                List<GSDSMSCreateCase.GSD_SMS_Bulk_Part_Request_xcNotification> lstRequest = new List<GSDSMSCreateCase.GSD_SMS_Bulk_Part_Request_xcNotification>();                        
                GSD_Integration_Data__c gsdintegrationConfig = GSD_Integration_Data__c.getValues('SMSCreateCase');                
                ObjNotification.endpoint_x= gsdintegrationConfig.End_point_URL__c;//'https://api-csc-stg-sgw.ext.hpe.com/gw/hpit/gsd/gsd.sms.createcase.obm.dev';        
                ObjNotification.timeout_x=Integer.valueOf(gsdintegrationConfig.Time_out__c);
                ObjNotification.clientCertName_x=gsdintegrationConfig.Client_Certificate__c;
                Boolean response = false;
                ObjRequest.Product_number_xc = productNo;  
                ObjRequest.AccountName_xc = CurrContact.Account.Name; 
                ObjRequest.Serial_number_xc = serialNo;  
                ObjRequest.Trigger_Case_Create_xc = true;        
                ObjRequestParam.Id='00DW0000008q2mY';
                ObjRequest.AddressLine1_xc=lstAssets[0].Location__r.Street_Line_1__c;
                ObjRequest.AddressLine2_xc=lstAssets[0].Location__r.Street_Line_2__c;
                ObjRequest.City_xc=lstAssets[0].Location__r.City__c;
                ObjRequest.State_xc=lstAssets[0].Location__r.State__c;
                ObjRequest.Contact_first_name_xc=CurrContact.firstname;
                ObjRequest.Contact_last_name_xc = CurrContact.lastname;
                ObjRequest.Contact_phone_xc=CurrContact.phone;           
                ObjRequest.Contact_email_xc=CurrContact.email;
                ObjRequest.Country_xc=lstAssets[0].Location__r.World_Region1__r.name;
                ObjRequest.CurrencyIsoCode='';
                ObjRequest.Customer_Case_Id_xc=strCaseReferenceId;
                ObjRequest.Environment_xc=lstAssets[0].name;                        
                ObjRequest.Install_xc=maps.get('Install');                  
                ObjRequest.Issue_xc=maps.get('Issue');                     
                ObjRequest.Name='';
                ObjRequest.Outage_xc=maps.get('Outage');                    
                ObjRequest.OwnerId='';
                ObjRequest.Part_number_xc=PartNumber;
                ObjRequest.PostalCode_xc=lstAssets[0].Location__r.Postal_Code__c;
                ObjRequest.Subject_xc=lstAssets[0].name+' SMS part order';          
                ObjRequestParam.sObject_x = ObjRequest;
                lstRequest.Add(ObjRequestParam);
                system.debug('lstRequest:'+lstRequest);
                response = ObjNotification.notifications('00DW0000008q2mY','00DW0000008q2mY','00DW0000008q2mY','00DW0000008q2mY','00DW0000008q2mY',lstRequest);
                system.debug('responseofObjNotification:'+response);
                if(string.valueof(response).equals('true'))
                {
                    popdisplay=true;
                }
                else
                    ApexPages.addmessage(new Apexpages.Message(ApexPages.Severity.Error,system.label.GSD_SMS_UnableToCreatePartRequestError));
            }
            catch(Exception ex)
            {
                ApexPages.addmessage(new Apexpages.Message(ApexPages.Severity.Error,system.label.GSD_SMS_UnableToCreatePartRequestError));
            }  
        }
    }
    
    
    public continuation partSelector()
    {        
        displayPopup = true;
        string transactionId = 'transa-123';
        continuation continuationobject_BOM = new continuation(120);
        continuationobject_BOM.continuationMethod = 'BOMCallBack';
        GSDBomclass.BOMRequest_element objbomtrquest=new GSDBomclass.BOMRequest_element();
        objbomtrquest.ISO2CharacterCountryCode='US' ;
        objbomtrquest.ProductIdentifier=productNo;
        objbomtrquest.ProductSerialNumber=serialNo;
        //Commented hardcoding of clientname - 12.1 warranty
        //objbomtrquest.ClientName='PS';
        objbomtrquest.ClientType='Internal';
        objbomtrquest.CountryGeographyIdentifier='';
        objbomtrquest.IncludeComponentBOMFlag='true';
        objbomtrquest.IncludeEnhancedBOMFlag='true';
        objbomtrquest.IncludeMultiVendorFlag='false';
        objbomtrquest.IncludeOrderabilityFlag='true';
        // monitor input section- section
        GSDBomclass.Monitoring_element Monitoringobj=new GSDBomclass.Monitoring_element();
        System.debug('on submit transactionid:'+transactionId);
        Monitoringobj.TransactionID=transactionId;
        
        GSDBomclass.RequestNameValue_element objrequest=new GSDBomclass.RequestNameValue_element();
        objrequest.Name='PartOrderId';
        //objrequest.value=objorder[0].legacy_part_order_number__C;
        Monitoringobj.RequestNameValue = objrequest;
        
        AsyncAsyncGSDBomclass.AsyncBillOfMaterial objsoapsource=new AsyncAsyncGSDBomclass.AsyncBillOfMaterial();
        GSD_Integration_Data__c  gsdintegrationConfig = GSD_Integration_Data__c.getValues('BOM');
        objsoapsource.clientCertName_x=gsdintegrationConfig.Client_Certificate__c;//ClientCertificate;
        objsoapsource.endpoint_x=gsdintegrationConfig.End_point_URL__c; 
        objsoapsource.timeout_x =integer.valueof(gsdintegrationConfig.Time_out__c);
        //Mapped clientname from custom setting- 12.1 warranty
        objbomtrquest.ClientName=gsdintegrationConfig.End_Point_Password__c;
        GetBOM=objsoapsource.beginBillOfMaterial(continuationobject_BOM,Monitoringobj,objbomtrquest);
        return continuationobject_BOM;
        // objmonitorutility.endMon(inputAttribute)        
    }
    
    // Wrapper for ComponentBOM
    public class compnentBOMItem
    {
        public String PartIdentifier2{get;set;}  public String PartExtendedDescription2{get;set;}   public String Quantiy{get;set;}   public String Returnable{get;set;}
    }
    // Wrapper for Part order line
    public class Wrapper
    {
        public Boolean isCheckBox{get;set;}
        public String PartIdentifier2{get;set;}
        public String PartExtendedDescription2{get;set;}
        public String CSR {get;set;}
        public String ROHS{get;set;}
        public String SourceSystemKey{get;set;}
        public String ROHSComplaint{get;set;}
        public String Returnable{get;set;}
        public String PartImageFlag{get;set;}
        public String PartImageUrl{get;set;}
        public string isPartOrderabilityStatusCode{get;set;}
        public Boolean selectchk{get;set;}
        public Integer qty {get;set;}
        public String PartCategoryCode{get;set;}
        public Boolean isPartOrderable{get;set;}
        
        public wrapper(){
            isCheckBox = FALSE;
            PartIdentifier2 = '';
            PartExtendedDescription2='';
            CSR='';
            ROHS='';
            SourceSystemKey='';
            ROHSComplaint='';
            Returnable='';
            PartImageFlag='';
            PartImageUrl='';
            isPartOrderabilityStatusCode='';
            selectchk=false;
            qty =0;
            PartCategoryCode='';
            isPartOrderable = false;
        }
        
    }

    public Object BOMCallBack()
    {      
        system.debug('Inside BOM call back');
        partSurferUrl = GSD_Integration_Data__c.getInstance('Part_Surfer').End_point_URL__c;  
        dtStartTime = system.now();
        try
        {
            string transactionId = 'transa-123';            
            output= GetBOM.getValue();  
            system.debug('output:'+ output);          
            MonitorUtility.MonitorInputAttributes inputAttributeobj=new MonitorUtility.MonitorInputAttributes();
            inputAttributeobj.StartTime = dtStartTime; 
            inputAttributeobj.EndTime=system.now();
            inputAttributeobj.TransactionID=transactionId;
            inputAttributeobj.Component='SF-BillOfMaterial';
            inputAttributeobj.SubComponent='BOM';
            inputAttributeobj.Organization='GSD';
            inputAttributeobj.Domain='FSM';
            inputAttributeobj.Source='SFDC';
            inputAttributeobj.EndUser=userInfo.getusername();
            inputAttributeobj.ResponseBody='';
            inputAttributeobj.ResponseStatus='200';
            inputAttributeobj.ResponseText ='Pass';
            inputAttributeobj.RequestKeyName1='CaseId';
            //inputAttributeobj.RequestKeyValue1=casenumbervalue[0];
            inputAttributeobj.RequestKeyName2='SerialNumber';
            //inputAttributeobj.RequestKeyValue2=ProductSerialNumber;
            inputAttributeobj.RequestKeyName3='ProductNumber';
            //inputAttributeobj.RequestKeyValue3=productIdentifier;
            inputAttributeobj.RequestKeyName4='PartOrderId';
           //inputAttributeobj.RequestKeyValue4=legacypartordernumber;
            
            objmonitorutility.endMon(inputAttributeobj) ;
            
            componentBOMList = new list<compnentBOMItem>();
            //strProductROHS =output.RestrictionOnHazardousSubstancesCode;
            /*for(GSDBomclass.SerializedProductInstance comResult : output.SerializedProductInstanceList.SerializedProductInstanceList)                
            {
                compnentBOMItem item = new compnentBOMItem(); 
                item.PartIdentifier2 = comResult.PartIdentifier;        
                item.PartExtendedDescription2 = comResult.PartDescription;                     
                item.Quantiy = comResult.PartQuantity; 
                item.Returnable=comResult.PartReturnableCode; 
                componentBOMList.add(item);
            }
            system.debug('componentBOMList'+componentBOMList.size());     */
            
            for(GSDBomclass.ProductSupportPart result : output.ProductSupportPartList.ProductSupportPartList) 
            {   
                Wrapper wrp = new Wrapper();  
                wrp.isCheckBox = false;  
                wrp.isPartOrderabilityStatusCode='0';  
                if(result.PartOrderabilityStatusCode == '1' &&  result.CompliantWithProductFlag=='Y')  
                {  
                    wrp.isPartOrderabilityStatusCode= '1';  
                    wrp.qty=1; 
                    wrp.isPartOrderable = true;
                } 
                wrp.PartIdentifier2 = result.PartIdentifier; 
                wrp.PartExtendedDescription2 = result.PartExtendedDescription; 
                //wrp.CSR=result.CustomerSelfRepairCode;
                //wrp.ROHS=result.RestrictionOnHazardousSubstanceCode; 
                //wrp.Returnable=result.PartReturnableCode; 
                //wrp.ROHSComplaint=result.CompliantWithRoHSJurisdictionFlag; 
                wrp.PartImageFlag=result.PartImageFlag; 
                wrp.PartImageUrl=partSurferUrl+'=' + result.PartIdentifier; 
                //wrp.PartCategoryCode=result.PartCategoryCode; 
                spareBomList.add(wrp); 
            }                             
            main.addAll(spareBomList);
            system.debug('spareBomList:'+spareBomList.size());
            //for( Wrapper itr :  spareBomList)  {  if(itr.isCheckBox){  buttonCheck=false;  } else{buttonCheck=true; }  }postback=true;
                        
        }
        Catch(Exception exceptionMsg)
        {       
            String testBomException=exceptionMsg.getMessage();
            system.debug('.........testBomException'+testBomException);     
            system.debug('.........testBomException'+exceptionMsg.getStackTraceString());               
        } 
        return null;
    }

   
    public pagereference okinpopup(){
        
        
        String headerdata= ApexPages.currentPage().getHeaders().get('Host');
        String urlvalue = '/SMS/apex/GSDSMSViewPartRequests?sfdc.tabName='+GSD_SMS_Configuration__c.getValues('ViewPartRequest').Configdata__c;
        
        string urls='https://' + headerdata+ urlvalue;
        
        pagereference pageviewinstall=new pagereference(urls);
        pageviewinstall.setRedirect(true); 
        return pageviewinstall;
        
        
    }

     public pagereference CancelAction()
     {                
        String headerdata= ApexPages.currentPage().getHeaders().get('Host');
        String urlvalue = '/SMS/apex/GSDSMSCreatePartRequest?sfdc.tabName='+GSD_SMS_Configuration__c.getValues('CreatePartRequest').Configdata__c;        
        string urls='https://' + headerdata+ urlvalue;        
        pagereference pageviewinstall=new pagereference(urls);
        pageviewinstall.setRedirect(true); 
        return pageviewinstall;
    }
    
    public void closePopup() {
spareBomList.clear();
    displayPopup = false;
    }

    public void selectpart(){
        PartNumber = ApexPages.currentPage().getParameters().get('selectedPartNumber');
        /*for(wrapper wrapp:spareBomList){
            if(wrapp.isCheckBox ){
                PartNumber=wrapp.PartIdentifier2;
            }
        }*/
      displayPopup = false;
    }
    public PageReference redirectPopup(){
        system.debug('PartNumber***'+PartNumber);
        if(PartNumber!=null){
            flag=true;
            system.debug('PartNumber***'+PartNumber);
        }        
        displayPopup = false;
        return null;
    }
}