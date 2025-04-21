# ✨ AIOpportunityEmailSuggestion-Salesforce

AIOpportunityEmailSuggestion-Salesforce is a Lightning Web Component (LWC) built for Salesforce that leverages AI to automatically generate personalized emails based on Opportunity, Tasks, Events and Contact data. This tool helps Sales Reps save time, maintain consistency, and enhance communication with leads and customers.

---

## ⚙️ Features

- 🔮 **AI-Powered Email Generation**  
  Generates contextual emails using Opportunity & Contact details.

- ✍️ **Editable Suggestions**  
  Users can tweak and finalize emails before sending.

- 📤 **One-Click Send Email**  
  Sends the generated email directly from Salesforce.

- 🔁 **Dynamic Spinner & UI Feedback**  
  Visual indicators during generation & sending processes.

---

## 🧱 Components

- `AIOpportunityEmailSuggestion`  
  Main LWC with the following elements:
  - **Generate Email** button
  - **Loading Spinner**
  - **Lightning Textarea** to show the generated content
  - **Send Email** button

- **Backend Apex Class (Optional)**  
  Use for calling external AI services via REST API or for additional processing.

---

## 🚀 How to Use

1. Navigate to an **Opportunity Record Page**.
2. Click **Generate Email**.
3. The email will be generated based on:
   - Contact's first name
   - Opportunity stage
   - Product details (if added)
4. Edit the content if needed.
5. Click **Send Email** to send it directly.

---

## 📦 Installation

1. Clone or download this repository.
2. Deploy the LWC to your Salesforce Org:
   - Use **VS Code + Salesforce CLI**
   - Or manually upload via **Developer Console**
3. Add the component to an **Opportunity Lightning Page** via Lightning App Builder.

---

## 🧠 Example Prompt Logic (if integrated with AI service)

```text
"Generate a professional follow-up email for {ContactName} regarding {OpportunityName} which is currently in {StageName} stage. Include value props of the associated product: {ProductName}."
