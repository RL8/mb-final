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
import { useConversationStore } from '~/composables/useConversationStore';
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
        conversation_id: null
      }
    });
    
    // Process response
    if (response.message) {
      conversationStore.addMessage({
        content: response.message,
        sender: 'ai',
        timestamp: new Date()
      });
    }
    
    // Set conversation ID if provided
    if (response.conversation_id) {
      conversationStore.setConversationId(response.conversation_id);
    }
    
  } catch (error) {
    console.error('Error getting initial greeting:', error);
  }
});
</script>

<style>
/* Global styles */
:root {
  --primary-color: #4F46E5;
  --primary-dark: #4338ca;
  --text-color: #212529;
  --text-light: #6c757d;
  --bg-color: #f8f9fa;
  --border-color: #dee2e6;
  --shadow-sm: 0 1px 3px rgba(0, 0, 0, 0.1);
  --shadow-md: 0 4px 6px rgba(0, 0, 0, 0.1);
  --radius-sm: 6px;
  --radius-md: 12px;
}

* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
  color: var(--text-color);
  background-color: var(--bg-color);
  line-height: 1.5;
}

.app-container {
  display: flex;
  height: 100vh;
  overflow: hidden;
}

.main-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  height: 100%;
  overflow: hidden;
}

.app-header {
  padding: 16px 24px;
  background-color: white;
  border-bottom: 1px solid var(--border-color);
  box-shadow: var(--shadow-sm);
  z-index: 10;
}

.app-header h1 {
  font-size: 1.5rem;
  color: var(--primary-color);
  margin: 0;
}

/* Responsive adjustments */
@media (max-width: 768px) {
  .app-container {
    flex-direction: column;
  }
  
  .app-header {
    padding: 12px 16px;
  }
  
  .app-header h1 {
    font-size: 1.2rem;
  }
}
</style>
