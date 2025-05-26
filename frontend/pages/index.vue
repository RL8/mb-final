<template>
  <div class="chat-page">
    <!-- Chat history with collapsible exchange units -->
    <div class="chat-history">
      <h2>Chat History</h2>
      
      <!-- Demo exchange unit with hardcoded content -->
      <CollapsibleExchangeUnit 
        :exchange="{
          id: 'demo_exchange',
          title: 'Initial Greeting',
          timestamp: new Date(),
          messages: [
            {
              content: 'Hello! I am your AI assistant. How can I help you today?',
              sender: 'ai',
              timestamp: new Date()
            },
            {
              content: 'Hello there!',
              sender: 'user',
              timestamp: new Date()
            },
            {
              content: 'I see you\'re new here. Could you please tell me your name so I can address you properly?',
              sender: 'ai',
              timestamp: new Date()
            }
          ],
          sideboardContent: {
            title: 'Welcome Information',
            content: '<p>Welcome to MindBridge Chat! This is a demonstration of the sideboard content that can be displayed alongside your conversation.</p><p>The sideboard can contain helpful information, links, and other resources related to your current conversation.</p>'
          },
          isComplete: true
        }"
      />
      
      <!-- Dynamic exchange units from conversation store -->
      <CollapsibleExchangeUnit 
        v-for="exchange in exchanges" 
        :key="exchange.id"
        :exchange="exchange"
        :initialCollapsed="false"
      />
    </div>
    
    <!-- Live chat interface -->
    <div class="live-chat">
      <h2>Current Conversation</h2>
      <ChatInterface />
    </div>
  </div>
</template>

<script setup>
import { useConversationStore } from '~/composables/useConversationStore';
import { computed } from 'vue';

// Get conversation store
const conversationStore = useConversationStore();

// Computed properties
const exchanges = computed(() => conversationStore.exchanges);
</script>

<style scoped>
.chat-page {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 24px;
  height: calc(100vh - 40px);
}

.chat-history, .live-chat {
  display: flex;
  flex-direction: column;
  background-color: white;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  padding: 20px;
  overflow: hidden;
}

h2 {
  margin-top: 0;
  margin-bottom: 16px;
  color: var(--primary-color);
  font-size: 1.3rem;
}

.chat-history {
  overflow-y: auto;
}

.live-chat {
  display: flex;
  flex-direction: column;
}

.live-chat > :deep(.chat-interface) {
  flex: 1;
  box-shadow: none;
  background-color: transparent;
}

@media (max-width: 768px) {
  .chat-page {
    grid-template-columns: 1fr;
    height: auto;
  }
  
  .chat-history {
    max-height: 50vh;
  }
  
  .live-chat {
    height: 50vh;
  }
}
</style>
