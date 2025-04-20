import { LightningElement, api, track } from 'lwc';
import getEmailSuggestion from '@salesforce/apex/OpportunityEmailSuggestionController.getEmailSuggestion';

export default class OpportunityEmailSuggestion extends LightningElement {
    @api recordId;
    @track emailContent = '';
    @track showEmailEditor = false;
    @track isLoading = false; // Controls the spinner and button state

    get generateButtonLabel() {
        return this.isLoading ? 'Generating...' : 'Generate Email';
    }

    // Fetch suggested email
    handleGenerateEmail() {
        this.isLoading = true;
        this.emailContent = 'Generating email...';

        getEmailSuggestion({ opportunityId: this.recordId })
            .then(data => {
                setTimeout(() => {
                    this.emailContent = data || 'No response received.';
                    this.showEmailEditor = true;
                    this.isLoading = false;
                }, 1000); // Simulated delay for UI smoothness
            })
            .catch(error => {
                this.emailContent = 'Error generating email. Please try again.';
                console.error('Error fetching email:', error);
                this.isLoading = false;
            });
    }

    // Handle textarea change
    handleEmailChange(event) {
        this.emailContent = event.target.value;
    }
}