public with sharing class assignTracksAndLCsPageController{
     public String selectedSite  {get;set;}
     public String assignUassign  {get;set;}
     public String selectedTrack  {get;set;}
     public String selectedCohort  {get;set;}
     public String globalselectedLC  {get;set;}
     public String globalselectedTrack {get;set;} 
     public Integer count{get;set;}
     public List<SelectOption> cohortOptions {get;set;}     
     public List<SelectOption> siteOptions {get;set;}
     public List<SelectOption> assignUassignOptions {get;set;}
     public List<SelectOption> trackOptions {get;set;}
     public List<SelectOption> Lcoptions{get;set;} 
     public List<Engagement__c> Enagements{get;set;}
     public List<WrapperClass> wrapList{get;set;}  
     //public Map<String,String> lcOptionsMap {get;set;}
     
     public assignTracksAndLCsPageController()
     {    
        wrapList = new List<WrapperClass>();       
        selectedCohort = '';
        cohortOptions = new List<SelectOption>();
        cohortOptions.add(new SelectOption('--None--','--None--'));
        for(cohort__c obj :[SELECT Id, Name FROM cohort__c] )
        {
            cohortOptions.add(new SelectOption(obj.Name,obj.Name));
        }
        selectedSite = '';
        siteOptions = new List<SelectOption>();
        siteOptions.add(new SelectOption('--None--','--None--'));
        for(Site__c obj :[SELECT Id, Name FROM Site__c] )
        {
            siteOptions.add(new SelectOption(obj.Name,obj.Name));
        }
        assignUassign = '';
        assignUassignOptions = new List<SelectOption>();
        assignUassignOptions.add(new SelectOption('--None--','--None--'));
        assignUassignOptions.add(new SelectOption('Assigned','Assigned'));
        assignUassignOptions.add(new SelectOption('Unassigned','Unassigned'));    
        //lcOptionsMap = new Map<String,String>();  
        Lcoptions = new List<SelectOption>();
        Lcoptions.add(new SelectOption('','--Unassigned--'));
        
        selectedTrack = '';
        trackOptions = new List<SelectOption>();
        trackOptions.add(new SelectOption('--Unassigned--','--Unassigned--'));
        Schema.DescribeFieldResult fieldResult = Engagement__c.Track_Assignment__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();        
        for( Schema.PicklistEntry f : ple)
           {
              trackOptions.add(new SelectOption(f.getLabel(), f.getValue()));
           }  
     }     
    
     public pagereference fetchEngagements(){
         if(selectedCohort== '--None--' && selectedSite== '--None--'){         
             ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Please select Cohort and Site');
             ApexPages.addMessage(myMsg);
             return null; 
         } 
         if(wrapList!=null)
         wrapList.clear();    
         
         integer i=0;
         List<String> statusValues= new List<String> {'Accepted','Conditionally Accepted','Enrolled'};
         try{  
             String Query= 'SELECT id, Name, Site__c,Track_Assignment__c,Secondary_Specialty_Assignment__c,Site_Location__c,Site_Location__r.Tracks__c,Student_Full_Name__c ,Prospect_Track_Interest__c , Learning_Community__c,Cohort__c,Learning_Community__r.Name FROM Engagement__c WHERE (Cohort__c=:selectedCohort AND Site__c=:selectedSite)';        
             if(assignUassign=='Unassigned'){            
                Query += ' AND Learning_Community__c=null';  
             }else if(assignUassign=='Assigned'){            
                Query += ' AND Learning_Community__c!=null';  
                System.debug('Query '+Query );
             }
             Query +=' AND Status__c IN:statusValues';          
             
             for(Engagement__c eng : Database.query(Query)){  
                    if(eng.Learning_Community__c==null){            
                        wrapList.add(new WrapperClass(eng,Lcoptions,'--Unassigned--',i)); 
                        System.debug('wrapList '+wrapList);           
                    } else{            
                        wrapList.add(new WrapperClass(eng,Lcoptions,eng.Learning_Community__c,i));   
                    }           
                    i++;
                } 
          }catch (exception e){
              ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'' + e));
              return null;
          }
          return null;
     }
     
     /*public void refreshPage(){
         for(WrapperClass wr: wrapList){
            if (wr.rowcount==count && wr.selectedLC!='' || wr.selectedLC!=null){                
                wr.selectedLC = lcOptionsMap.get(wr.selectedLC);  
            }       
         }
     }*/
     public void applyGlobalchanges(){  
         System.debug('I am inside the global chnages' + globalselectedLC);                 
         for(WrapperClass wr: wrapList){ 
             if (globalselectedLC!=null && wr.selected){ 
                 wr.selectedLC = globalselectedLC;
                 } 
             if(globalselectedTrack != '--Unassigned--'){                   
                 wr.eng.Track_Assignment__c= globalselectedTrack;                 
                 System.debug('I am inside the global chnages' +wr.eng.Track_Assignment__c); 
                   
             }          
         }      
     }
     public Pagereference lcOptionslist(){              
         for(Learning_Community__c obj :[SELECT Id, Name 
                                         FROM Learning_Community__c 
                                         WHERE Cohort__c=:selectedCohort  
                                        ])
           {
             Lcoptions.add(new SelectOption(obj.Id,obj.Name));
             //lcOptionsMap.put(obj.Id,obj.Name);           
           }
         return null;
     }
     public pagereference updateEngagements(){ 
         System.debug('wrapList ************ '+wrapList);
         boolean pageError = false; 
         String styleSheet = 'border-radius: 10px 10px 10px 10px; -moz-border-radius: 10px 10px 10px 10px; -webkit-border-radius: 10px 10px 10px 10px; border: 3px solid red;';       
         if(wrapList!=null && wrapList.size()==0 ) { 
         ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Nothing to Update '));
                 return null;  
                 }
         //Site__c siteSpecialities =[Select Id,Name,Tracks__c from Site__c WHERE Name=:selectedSite AND Cohort__r.Name=:selectedCohort LIMIT 1];
         Site__c siteSpecialities = getSites();
         try{ 
              list<Engagement__c> enList=new list<Engagement__c>();              
                 for(WrapperClass wr: wrapList){ 
                    if(wr.selectedLC!='' && wr.selectedLC!=null && wr.selectedLC!='--Unassigned--' ){  
                         Engagement__c en= new Engagement__c();
                         en.id = wr.eng.Id; 
                         en.Learning_Community__c= wr.selectedLC;                        
                         if(wr.eng.Track_Assignment__c !=null && JSON.serialize(siteSpecialities.Tracks__c).contains(wr.eng.Track_Assignment__c)){                               
                             wr.specialCheck ='';
                             en.Track_Assignment__c = wr.eng.Track_Assignment__c; 
                         }else if(wr.eng.Track_Assignment__c !=null && wr.eng.Track_Assignment__c !='--None--'){                              
                             wr.specialCheck =styleSheet;
                             if(pageError ==false)
                             ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please select the correct Specialty. Available Specialties for this Site are: '+siteSpecialities.Tracks__c));
                             pageError = true;                             
                         }                         
                         if(wr.eng.Secondary_Specialty_Assignment__c !=null && JSON.serialize(siteSpecialities.Tracks__c).contains(wr.eng.Secondary_Specialty_Assignment__c)){  
                             wr.secondSpecialCheck ='';
                             en.Secondary_Specialty_Assignment__c = wr.eng.Secondary_Specialty_Assignment__c; 
                         }else if(wr.eng.Secondary_Specialty_Assignment__c !=null && wr.eng.Secondary_Specialty_Assignment__c !='--None--') { 
                             System.debug('wr.eng.Secondary_Specialty_Assignment__c '+wr.eng.Secondary_Specialty_Assignment__c); 
                                                        
                             wr.secondSpecialCheck =styleSheet;
                             if(pageError ==false)
                             ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please select the correct Specialty. Available Specialties for this Site are: '+siteSpecialities.Tracks__c));                             
                             pageError = true;
                         }                        
                         System.debug('enList Site'+wr.eng.Site_Location__c );                        
                         enList.add(en);             
                     }  
                                        
                 }                  
                 if(enList.size()>0 &&  pageError == false){
                     System.debug(enList);                       
                     Database.update(enList);
                     ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,'Records Updated Successfully. Thank you!'));
                     }
                  }
             
         catch(System.DmlException e){
                 ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,' ' +e));
                 return null;
             }             
         return null;
     }
    
    @TestVisible
    private Site__c getSites(){
        Site__c siteSpecialities =[Select Id,Name,Tracks__c from Site__c WHERE Name=:selectedSite LIMIT 1];
        System.debug('siteSpecialities '+siteSpecialities);
        return siteSpecialities;
    }
     
     public class WrapperClass{
            public Engagement__c eng {get; set;}
            public List<SelectOption> selectedCLC{get; set;}
            public String selectedLC{get; set;}
            public integer rowcount{get;set;}
            public String specialCheck {get;set;} 
            public String secondSpecialCheck {get;set;}            
            public boolean selected{get;set;}
            public WrapperClass(Engagement__c e,List<SelectOption> clc, String lc, integer r ){                
                eng = e;                
                selectedCLC = clc;
                selectedLC = lc;
                rowcount = r;               
                selected = false;
                specialCheck ='';  
                secondSpecialCheck ='';  
            }
        }
}