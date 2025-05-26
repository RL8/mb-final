<template>
  <div class="app-container">
    <!-- Main chat interface -->
    <div class="main-content">
      <header class="app-header">
        <h1>MindBridge Chat</h1>
      </header>
      
      <!-- Chat interface component -->
      <ChatInterface />
      
      <!-- Contextual input module (conditionally rendered) -->
      <ContextualInputModule 
        v-if="activeComponent && activeComponent.type === 'contextual_input'"
        :componentId="activeComponent.id"
        :title="activeComponent.data?.title || 'Input Required'"
        :description="activeComponent.data?.description || ''"
        :inputType="activeComponent.data?.inputType || 'text'"
        :inputLabel="activeComponent.data?.inputLabel || 'Please enter your response:'"
        :placeholder="activeComponent.data?.placeholder || ''"
        :options="activeComponent.data?.options || []"
        :required="activeComponent.data?.required !== false"
        :allowCancel="activeComponent.data?.allowCancel !== false"
        :saveButtonText="activeComponent.data?.saveButtonText || 'Save'"
        :validationRules="activeComponent.data?.validationRules || {}"
      />
    </div>
    
    <!-- Sideboard panel -->
    <SideboardPanel />
  </div>
</template>

<script setup>
// useConversationStore is auto-imported from the composables directory
import { computed, onMounted } from 'vue';

// Get conversation store
const conversationStore = useConversationStore();

// Computed properties
const activeComponent = computed(() => conversationStore.activeComponent);

// Initial greeting when app loads
onMounted(async () => {
  try {
    // Call the API to get initial greeting
    const response = await $fetch('/api/chat', {
      method: 'POST',
      body: {
        message: 'start',
        conversationId: null
      }
    });
    
    // Process the response
    if (response.conversationId) {
      conversationStore.setConversationId(response.conversationId);
    }
    
    if (response.message) {
      conversationStore.addMessage({
        id: `msg_${Date.now()}`,
        content: response.message,
        sender: 'ai',
        timestamp: new Date()
      });
    }
    
    // Handle any components or sideboard content in the response
    if (response.components && response.components.length > 0) {
      const component = response.components[0];
      conversationStore.setActiveComponent(component.id, component);
    }
    
    if (response.sideboardContent) {
      conversationStore.updateSideboard(
        response.sideboardContent.id,
        response.sideboardContent
      );
    }
  } catch (error) {
    console.error('Error fetching initial greeting:', error);
    // Display error message
    conversationStore.addMessage({
      id: `msg_${Date.now()}`,
      content: 'Sorry, I encountered an error while starting our conversation. Please try again.',
      sender: 'ai',
      timestamp: new Date()
    });
  }
});
</script>

<style>
.app-container {
  display: flex;
  height: 100vh;
  width: 100%;
  overflow: hidden;
}

.main-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.app-header {
  padding: 1rem;
  background-color: #4F46E5;
  color: white;
  text-align: center;
}

.app-header h1 {
  margin: 0;
  font-size: 1.5rem;
}
</style>
