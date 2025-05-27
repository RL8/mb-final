<template>
  <div class="test-flow-page">
    <h1>Hello World Flow Test</h1>
    
    <div class="flow-container">
      <div class="flow-step" :class="{ 'active': currentStep >= 1, 'completed': currentStep > 1 }">
        <div class="step-number">1</div>
        <div class="step-content">
          <h3>Initial Greeting</h3>
          <p>When the app loads, the AI should send an initial greeting message.</p>
          <div v-if="initialGreeting" class="status success">✅ Received: {{ initialGreeting }}</div>
          <div v-else class="status pending">⏳ Waiting for initial greeting...</div>
        </div>
      </div>
      
      <div class="flow-step" :class="{ 'active': currentStep >= 2, 'completed': currentStep > 2 }">
        <div class="step-number">2</div>
        <div class="step-content">
          <h3>User "Hello" Message</h3>
          <p>Send "Hello" to the AI to trigger the greeting flow.</p>
          <button @click="sendHello" :disabled="currentStep !== 1 || isSending">Send "Hello"</button>
          <div v-if="helloResponse" class="status success">✅ Response: {{ helloResponse }}</div>
          <div v-else-if="isSending" class="status pending">⏳ Sending message...</div>
        </div>
      </div>
      
      <div class="flow-step" :class="{ 'active': currentStep >= 3, 'completed': currentStep > 3 }">
        <div class="step-number">3</div>
        <div class="step-content">
          <h3>Name Input Trigger</h3>
          <p>The AI should trigger the ContextualInputModule for name input.</p>
          <div v-if="nameInputTriggered" class="status success">✅ Name input triggered</div>
          <div v-else class="status pending">⏳ Waiting for name input trigger...</div>
        </div>
      </div>
      
      <div class="flow-step" :class="{ 'active': currentStep >= 4, 'completed': currentStep > 4 }">
        <div class="step-number">4</div>
        <div class="step-content">
          <h3>User Enters Name</h3>
          <p>Enter your name in the ContextualInputModule when it appears.</p>
          <div v-if="nameSubmitted" class="status success">✅ Name submitted: {{ submittedName }}</div>
          <div v-else class="status pending">⏳ Waiting for name submission...</div>
        </div>
      </div>
      
      <div class="flow-step" :class="{ 'active': currentStep >= 5, 'completed': currentStep > 5 }">
        <div class="step-number">5</div>
        <div class="step-content">
          <h3>Sideboard Update</h3>
          <p>The AI should update the Sideboard with a welcome message.</p>
          <div v-if="sideboardUpdated" class="status success">✅ Sideboard updated</div>
          <div v-else class="status pending">⏳ Waiting for sideboard update...</div>
        </div>
      </div>
      
      <div class="flow-step" :class="{ 'active': currentStep >= 6 }">
        <div class="step-number">6</div>
        <div class="step-content">
          <h3>Chat History Update</h3>
          <p>The conversation should be stored as a Collapsible Exchange Unit.</p>
          <div v-if="exchangeCreated" class="status success">✅ Exchange unit created</div>
          <div v-else class="status pending">⏳ Waiting for exchange creation...</div>
        </div>
      </div>
    </div>
    
    <!-- Live components for testing -->
    <div class="test-components">
      <div class="component-container">
        <h3>Chat Interface</h3>
        <ChatInterface />
      </div>
      
      <div class="component-container">
        <h3>Sideboard</h3>
        <SideboardPanel />
      </div>
      
      <!-- Contextual input module will appear when triggered -->
      <ContextualInputModule 
        v-if="showNameInput"
        componentId="name_input"
        title="What's Your Name?"
        description="Please enter your name so I can address you properly."
        inputType="text"
        inputLabel="Your Name"
        placeholder="Enter your name here"
        saveButtonText="Submit"
        @submit="onNameSubmit"
      />
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useConversationStore } from '~/composables/useConversationStore';

// State
const conversationStore = useConversationStore();
const currentStep = ref(0);
const initialGreeting = ref('');
const helloResponse = ref('');
const nameInputTriggered = ref(false);
const nameSubmitted = ref(false);
const submittedName = ref('');
const sideboardUpdated = ref(false);
const exchangeCreated = ref(false);
const isSending = ref(false);
const showNameInput = ref(false);

// Computed properties
const messages = computed(() => conversationStore.messages);
const activeComponent = computed(() => conversationStore.activeComponent);
const activeSideboardContent = computed(() => conversationStore.activeSideboardContent);
const exchanges = computed(() => conversationStore.exchanges);

// Methods
const sendHello = async () => {
  if (isSending.value) return;
  
  isSending.value = true;
  
  try {
    // Add user message to the conversation
    conversationStore.addMessage({
      content: 'Hello',
      sender: 'user',
      timestamp: new Date()
    });
    
    // Send message to API
    const response = await $fetch('/api/chat', {
      method: 'POST',
      body: {
        message: 'Hello',
        conversation_id: conversationStore.conversationId
      }
    });
    
    // Process response
    if (response.message) {
      helloResponse.value = response.message;
      conversationStore.addMessage({
        content: response.message,
        sender: 'ai',
        timestamp: new Date()
      });
      
      // Move to next step
      currentStep.value = 2;
    }
    
    // Check if name input was triggered
    if (response.component_id && 
        (response.component_id === 'name_input' || 
         response.component_id.includes('name'))) {
      nameInputTriggered.value = true;
      showNameInput.value = true;
      currentStep.value = 3;
    }
    
  } catch (error) {
    console.error('Error sending hello message:', error);
  } finally {
    isSending.value = false;
  }
};

const onNameSubmit = (name) => {
  submittedName.value = name;
  nameSubmitted.value = true;
  showNameInput.value = false;
  currentStep.value = 4;
};

// Watch for changes
watch(messages, (newMessages) => {
  if (newMessages.length > 0 && newMessages[0].sender === 'ai' && currentStep.value === 0) {
    initialGreeting.value = newMessages[0].content;
    currentStep.value = 1;
  }
});

watch(activeComponent, (newComponent) => {
  if (newComponent && 
      (newComponent.id === 'name_input' || 
       newComponent.id.includes('name'))) {
    nameInputTriggered.value = true;
    currentStep.value = 3;
  }
});

watch(activeSideboardContent, (newContent) => {
  if (newContent) {
    sideboardUpdated.value = true;
    currentStep.value = 5;
  }
});

watch(exchanges, (newExchanges) => {
  if (newExchanges.length > 0) {
    exchangeCreated.value = true;
    currentStep.value = 6;
  }
});

// Initialize
onMounted(() => {
  // Reset the conversation store for a clean test
  conversationStore.clearConversation();
  
  // Check for initial greeting after a short delay
  setTimeout(() => {
    if (messages.value.length > 0 && messages.value[0].sender === 'ai') {
      initialGreeting.value = messages.value[0].content;
      currentStep.value = 1;
    }
  }, 1000);
});
</script>

<style scoped>
.test-flow-page {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
}

h1 {
  text-align: center;
  margin-bottom: 30px;
  color: var(--primary-color);
}

.flow-container {
  display: flex;
  flex-direction: column;
  gap: 20px;
  margin-bottom: 40px;
}

.flow-step {
  display: flex;
  gap: 15px;
  padding: 20px;
  border-radius: 8px;
  background-color: #f8f9fa;
  border: 1px solid #dee2e6;
  opacity: 0.7;
  transition: all 0.3s ease;
}

.flow-step.active {
  opacity: 1;
  border-color: var(--primary-color);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.flow-step.completed {
  border-color: #28a745;
}

.step-number {
  width: 30px;
  height: 30px;
  border-radius: 50%;
  background-color: #adb5bd;
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: bold;
}

.flow-step.active .step-number {
  background-color: var(--primary-color);
}

.flow-step.completed .step-number {
  background-color: #28a745;
}

.step-content {
  flex: 1;
}

.step-content h3 {
  margin-top: 0;
  margin-bottom: 8px;
}

.step-content p {
  margin-bottom: 12px;
  color: #6c757d;
}

.status {
  margin-top: 10px;
  padding: 8px 12px;
  border-radius: 4px;
  font-size: 0.9rem;
}

.status.success {
  background-color: #d4edda;
  color: #155724;
}

.status.pending {
  background-color: #fff3cd;
  color: #856404;
}

button {
  padding: 8px 16px;
  background-color: var(--primary-color);
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  transition: background-color 0.2s;
}

button:hover:not(:disabled) {
  background-color: var(--primary-dark);
}

button:disabled {
  background-color: #adb5bd;
  cursor: not-allowed;
}

.test-components {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
}

.component-container {
  border: 1px solid #dee2e6;
  border-radius: 8px;
  padding: 15px;
  background-color: white;
  height: 400px;
  overflow: hidden;
}

.component-container h3 {
  margin-top: 0;
  margin-bottom: 15px;
  padding-bottom: 10px;
  border-bottom: 1px solid #dee2e6;
}

@media (max-width: 768px) {
  .test-components {
    grid-template-columns: 1fr;
  }
}
</style>
