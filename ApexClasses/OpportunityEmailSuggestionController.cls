public with sharing class OpportunityEmailSuggestionController {
    
    private static final String GEMINI_API_ENDPOINT = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key="Enter your API here or Use NamedCreds to use your API from there(bestPractice)';
    
    @AuraEnabled
    public static String getEmailSuggestion(Id opportunityId) {
        try {
            // Fetch Opportunity Details
            Opportunity opp = [SELECT Name, StageName FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
            
            // Fetch recent activities
            List<Task> activities = [SELECT Subject, Description FROM Task WHERE WhatId = :opportunityId ORDER BY CreatedDate LIMIT 3];
            
            // Fetch Opportunity Products
            List<OpportunityLineItem> products = [SELECT PricebookEntry.Product2.Name FROM OpportunityLineItem WHERE OpportunityId = :opportunityId];

            // Fetch Opportunity Contacts
            List<OpportunityContactRole> contacts = [SELECT Contact.Name, Role FROM OpportunityContactRole WHERE OpportunityId = :opportunityId];
            
            // Fetch Opportunity Contacts
            List<Event> activityEvent = [SELECT Subject, Description FROM Event WHERE WhatId = :opportunityId ORDER BY CreatedDate LIMIT 3];

            // Construct AI prompt
            String prompt = 'Make sure while creating the Mail you consider the Opportunity Stage,Recent Activities,Products Involved,Key Contacts Role from Below and Make sure you mention the Product Name in the Mail and after greeting use the Contacts First Name from.\n';
            prompt += 'Opportunity Name: ' + opp.Name + '\n';
            prompt += 'Stage: ' + opp.StageName + '\n';

            if (!activities.isEmpty()) {
                prompt += 'Recent Activities: ';
                for (Task t : activities) {
                    prompt += t.Subject + ' - ' + t.Description + '; ';
                }
                prompt += '\n';
            }

			if (!activityEvent.isEmpty()) {
                prompt += 'Recent Events: ';
                for (Event E : activityEvent) {
                    prompt += E.Subject + ' - ' + E.Description + '; ';
                }
                prompt += '\n';
            }

            if (!products.isEmpty()) {
                prompt += 'Products Involved: ';
                for (OpportunityLineItem oli : products) {
                    prompt += oli.PricebookEntry.Product2.Name + ', ';
                    System.debug('@@Product: ' + oli.PricebookEntry.Product2.Name);
                }
                prompt += '\n';
            }

            if (!contacts.isEmpty()) {
                prompt += 'Key Contact Details: Contact Name:' + contacts[0].Contact.Name + ' ( Contact Role :' + contacts[0].Role + ')\n';
                System.debug('@@Contact: ' + contacts[0].Contact.Name + ' (' + contacts[0].Role + ')');
            }

            // Prepare AI request
            List<Map<String, Object>> contentsList = new List<Map<String, Object>>();

            // AI System Instructions
            contentsList.add(new Map<String, Object>{
                'role' => 'model',
                'parts' => new List<Map<String, Object>>{
                    new Map<String, Object>{ 'text' => 'Generate a persuasive follow-up email for a sales opportunity. Make sure the email is short and convincing. Use the Contact first name from Contact Details in the greeting and Also while writing the mail keep in mind whom you are writing the mail i.e. keep in mind the role of the Contact from Contact Details, mention the Product Name, and do not include the Contact Role or extra details in the mail but you should consider in your thinking while writing the mail. Only return the email content.' }
                }
            });

            // User Query
            contentsList.add(new Map<String, Object>{
                'role' => 'user',
                'parts' => new List<Map<String, Object>>{
                    new Map<String, Object>{ 'text' => prompt }
                }
            });

            Map<String, Object> requestBody = new Map<String, Object>();
            requestBody.put('contents', contentsList);
            String requestBodyJson = JSON.serialize(requestBody);

            // HTTP Callout to Gemini API
            HttpRequest req = new HttpRequest();
            req.setEndpoint(GEMINI_API_ENDPOINT);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setTimeout(120000);
            req.setBody(requestBodyJson);

            Http http = new Http();
            HTTPResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> candidates = (List<Object>) responseMap.get('candidates');

                if (candidates != null && !candidates.isEmpty()) {
                    Map<String, Object> firstCandidate = (Map<String, Object>) candidates[0];
                    Map<String, Object> contentMap = (Map<String, Object>) firstCandidate.get('content');

                    if (contentMap != null) {
                        List<Object> parts = (List<Object>) contentMap.get('parts');

                        if (parts != null && !parts.isEmpty()) {
                            Map<String, Object> part = (Map<String, Object>) parts[0];
                            return (String) part.get('text');
                        } else {
                            return 'Error: No response parts found';
                        }
                    } else {
                        return 'Error: No content in AI response';
                    }
                } else {
                    return 'Error: No AI-generated candidates';
                }
            } else {
                return 'HTTP Error: ' + res.getStatusCode() + ' - ' + res.getStatus();
            }

        } catch (Exception e) {
            return 'Exception: ' + e.getMessage();
        }
    }
    
}