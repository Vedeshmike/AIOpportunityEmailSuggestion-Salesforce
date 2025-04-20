@isTest
public class OpportunityEmailSuggestionControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test data that will be used across test methods
        // Create standard price book if needed (this is usually not required as it exists by default)
        List<Pricebook2> standardPbs = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
        Pricebook2 standardPb;
        
        if (standardPbs.isEmpty()) {
            // Create a standard price book - in real scenarios you shouldn't need this
            // but test context might be different
            standardPb = new Pricebook2(
                Id = Test.getStandardPricebookId(),
                IsActive = true
            );
            update standardPb;
        } else {
            standardPb = standardPbs[0];
        }
    }
    
    @isTest
    static void testGetEmailSuggestion_Success() {
        // Create test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Contact testContact = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            AccountId = testAccount.Id
        );
        insert testContact;
        
        // Create test opportunity
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(30),
            AccountId = testAccount.Id
        );
        insert testOpportunity;
        
        // Create contact role
        OpportunityContactRole testContactRole = new OpportunityContactRole(
            OpportunityId = testOpportunity.Id,
            ContactId = testContact.Id,
            Role = 'Decision Maker'
        );
        insert testContactRole;
        
        // Create product and pricebook entry
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert testProduct;
        
        // Get standard price book ID using Test utility instead of query
        Id standardPricebookId = Test.getStandardPricebookId();
        
        // Create price book entry
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = testProduct.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert testPricebookEntry;
        
        // Create opportunity line item
        OpportunityLineItem testOpportunityLineItem = new OpportunityLineItem(
            OpportunityId = testOpportunity.Id,
            PricebookEntryId = testPricebookEntry.Id,
            Quantity = 1,
            UnitPrice = 100.00
        );
        insert testOpportunityLineItem;
        
        // Create tasks
        Task testTask = new Task(
            Subject = 'Test Task',
            Description = 'Task Description',
            WhatId = testOpportunity.Id,
            Status = 'Completed'
        );
        insert testTask;
        
        // Create events
        Event testEvent = new Event(
            Subject = 'Test Event',
            Description = 'Event Description',
            WhatId = testOpportunity.Id,
            StartDateTime = DateTime.now(),
            EndDateTime = DateTime.now().addHours(1)
        );
        insert testEvent;
        
        // Create mock HTTP response
        String mockResponseBody = '{"candidates":[{"content":{"parts":[{"text":"Subject: Follow-up on Test Opportunity\\n\\nDear John,\\n\\nThank you for considering Test Product for your needs. I wanted to follow up on our recent conversation about how we can help meet your requirements.\\n\\nBased on our previous discussion, I believe Test Product would be an excellent solution for your specific needs. Would you be available for a brief call next week to discuss implementation details?\\n\\nLooking forward to your response.\\n\\nBest regards,\\nYour Name"}],"role":"model"}}]}';
        Test.setMock(HttpCalloutMock.class, new GeminiAPIMock(mockResponseBody));
        
        // Start the test
        Test.startTest();
        String emailSuggestion = OpportunityEmailSuggestionController.getEmailSuggestion(testOpportunity.Id);
        Test.stopTest();
        
        // Verify the result
        System.assertNotEquals(null, emailSuggestion, 'Email suggestion should not be null');
        System.assert(emailSuggestion.contains('Dear John'), 'Email should contain contact first name');
        System.assert(emailSuggestion.contains('Test Product'), 'Email should mention the product');
    }
    
    @isTest
    static void testGetEmailSuggestion_NoContacts() {
        // Create test opportunity without contacts
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpportunity;
        
        // Create mock HTTP response
        String mockResponseBody = '{"candidates":[{"content":{"parts":[{"text":"Subject: Follow-up on Test Opportunity\\n\\nDear Prospect,\\n\\nI wanted to follow up on our discussion regarding Test Opportunity. Would you be available for a brief call to discuss next steps?\\n\\nLooking forward to your response.\\n\\nBest regards,\\nYour Name"}],"role":"model"}}]}';
        Test.setMock(HttpCalloutMock.class, new GeminiAPIMock(mockResponseBody));
        
        // Start the test
        Test.startTest();
        String emailSuggestion = OpportunityEmailSuggestionController.getEmailSuggestion(testOpportunity.Id);
        Test.stopTest();
        
        // Verify the result
        System.assertNotEquals(null, emailSuggestion, 'Email suggestion should not be null');
    }
    
    @isTest
    static void testGetEmailSuggestion_HTTPError() {
        // Create test opportunity
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpportunity;
        
        // Create mock HTTP response for error
        Test.setMock(HttpCalloutMock.class, new GeminiAPIErrorMock());
        
        // Start the test
        Test.startTest();
        String emailSuggestion = OpportunityEmailSuggestionController.getEmailSuggestion(testOpportunity.Id);
        Test.stopTest();
        
        // Verify the result
        System.assert(emailSuggestion.contains('HTTP Error'), 'Should return HTTP error message');
    }
    
    @isTest
    static void testGetEmailSuggestion_Exception() {
        // Create mock HTTP response that will throw an exception
        Test.setMock(HttpCalloutMock.class, new GeminiAPIExceptionMock());
        
        // Start the test
        Test.startTest();
        String emailSuggestion = OpportunityEmailSuggestionController.getEmailSuggestion(null); // Passing null to trigger exception
        Test.stopTest();
        
        // Verify the result
        System.assert(emailSuggestion.contains('Exception:'), 'Should return exception message');
    }
    
    // Mock classes for HTTP callouts
    private class GeminiAPIMock implements HttpCalloutMock {
        private String responseBody;
        
        public GeminiAPIMock(String responseBody) {
            this.responseBody = responseBody;
        }
        
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setStatus('OK');
            response.setBody(responseBody);
            return response;
        }
    }
    
    private class GeminiAPIErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(400);
            response.setStatus('Bad Request');
            response.setBody('{"error":"Invalid request"}');
            return response;
        }
    }
    
    private class GeminiAPIExceptionMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            // This will cause a null pointer exception when the response is processed
            throw new CalloutException('Simulated exception during callout');
        }
    }
}