<template>
  <div class="chat-interface">
    <!-- Messages container -->
    <div class="messages-container" ref="messagesContainer">
      <div v-for="(message, index) in messages" :key="index" 
           :class="['message', message.sender === 'ai' ? 'ai-message' : 'user-message']">
        <div class="message-content">
          {{ message.content }}
        </div>
        <div class="message-timestamp">
          {{ formatTimestamp(message.timestamp) }}
        </div>
      </div>
      <div v-if="isAiTyping" class="message ai-message typing">
        <div class="typing-indicator">
          <span></span>
          <span></span>
          <span></span>
        </div>
      </div>
    </div>

    <!-- Input area -->
    <div class="input-area" :class="{ 'disabled': inputDisabled }">
      <textarea 
        v-model="userInput" 
        placeholder="Type your message here..." 
        @keydown.enter.prevent="sendMessage"
        :disabled="inputDisabled"
        ref="userInputTextarea"
      ></textarea>
      <button @click="sendMessage" :disabled="!userInput.trim() || inputDisabled" class="send-button">
        <span class="send-icon">➤</span>
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, watch, nextTick } from 'vue';
import { useConversationStore } from '~/composables/useConversationStore';

// State
const userInput = ref('');
const isAiTyping = ref(false);
const inputDisabled = ref(false);
const messagesContainer = ref(null);
const userInputTextarea = ref(null);

// Get conversation store
const conversationStore = useConversationStore();
const { messages, conversationId } = conversationStore;

// Methods
const sendMessage = async () => {
  if (!userInput.value.trim() || inputDisabled.value) return;
  
  // Add user message to the conversation
  conversationStore.addMessage({
    content: userInput.value,
    sender: 'user',
    timestamp: new Date()
  });
  
  // Clear input and show typing indicator
  const sentMessage = userInput.value;
  userInput.value = '';
  isAiTyping.value = true;
  
  try {
    console.log('Sending message to API:', sentMessage);
    
    // Send message to API
    const response = await $fetch('/api/chat', {
      method: 'POST',
      body: {
        message: sentMessage,
        conversation_id: conversationId.value,
        metadata: {
          timestamp: new Date().toISOString(),
          client_info: {
            platform: navigator.platform,
            userAgent: navigator.userAgent,
            language: navigator.language
          }
        }
      }
    });
    
    console.log('API response:', response);
    
    // Process response
    isAiTyping.value = false;
    
    // Add AI response to conversation
    if (response.message) {
      conversationStore.addMessage({
        content: response.message,
        sender: 'ai',
        timestamp: new Date()
      });
    }
    
    // Handle UI component triggers if present
    if (response.component_id) {
      console.log('Activating component:', response.component_id);
      conversationStore.setActiveComponent(response.component_id, response.data || {});
      if (response.component_type === 'contextual_input' || 
          (response.data && response.data.type === 'contextual_input')) {
        inputDisabled.value = true;
      }
    }
    
    // Handle sideboard updates if present
    if (response.sideboard_display_id) {
      console.log('Updating sideboard:', response.sideboard_display_id);
      conversationStore.updateSideboard(response.sideboard_display_id, response.sideboard_data || {});
    }
    
    // Update conversation ID if provided
    if (response.conversation_id) {
      conversationStore.setConversationId(response.conversation_id);
    }
    
  } catch (error) {
    console.error('Error sending message:', error);
    isAiTyping.value = false;
    
    // Add error message to conversation
    conversationStore.addMessage({
      content: 'Sorry, there was an error processing your message. Please try again.',
      sender: 'ai',
      timestamp: new Date(),
      isError: true
    });
  }
};

// Format timestamp to readable format
const formatTimestamp = (timestamp) => {
  const date = new Date(timestamp);
  return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
};

// Auto-scroll to bottom when new messages arrive
watch(() => messages.value.length, async () => {
  await nextTick();
  if (messagesContainer.value) {
    messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight;
  }
});

// Enable input when contextual input is closed
watch(() => conversationStore.activeComponent, (newVal) => {
  inputDisabled.value = newVal !== null && newVal.type === 'contextual_input';
});

// Focus input on mount
onMounted(() => {
  if (userInputTextarea.value) {
    userInputTextarea.value.focus();
  }
});
</script>

<style scoped>
.chat-interface {
  display: flex;
  flex-direction: column;
  height: 100%;
  max-width: 800px;
  margin: 0 auto;
  background-color: #f8f9fa;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
}

.messages-container {
  flex: 1;
  overflow-y: auto;
  padding: 20px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.message {
  max-width: 80%;
  padding: 12px 16px;
  border-radius: 18px;
  position: relative;
  animation: fadeIn 0.3s ease-in-out;
}

.message-content {
  word-break: break-word;
  line-height: 1.5;
}

.message-timestamp {
  font-size: 0.7rem;
  opacity: 0.7;
  margin-top: 4px;
  text-align: right;
}

.ai-message {
  align-self: flex-start;
  background-color: #e9ecef;
  color: #212529;
  border-bottom-left-radius: 4px;
}

.user-message {
  align-self: flex-end;
  background-color: #4F46E5;
  color: white;
  border-bottom-right-radius: 4px;
}

.typing-indicator {
  display: flex;
  align-items: center;
  gap: 4px;
}

.typing-indicator span {
  width: 8px;
  height: 8px;
  background-color: #adb5bd;
  border-radius: 50%;
  display: inline-block;
  animation: bounce 1.4s infinite ease-in-out;
}

.typing-indicator span:nth-child(1) {
  animation-delay: 0s;
}

.typing-indicator span:nth-child(2) {
  animation-delay: 0.2s;
}

.typing-indicator span:nth-child(3) {
  animation-delay: 0.4s;
}

.input-area {
  display: flex;
  padding: 12px 16px;
  background-color: white;
  border-top: 1px solid #dee2e6;
  position: relative;
}

.input-area.disabled::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.05);
  z-index: 1;
}

textarea {
  flex: 1;
  border: none;
  padding: 12px;
  border-radius: 24px;
  resize: none;
  background-color: #f1f3f5;
  font-family: inherit;
  font-size: 1rem;
  min-height: 24px;
  max-height: 120px;
  outline: none;
  transition: background-color 0.3s;
}

textarea:focus {
  background-color: #e9ecef;
}

.send-button {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background-color: #4F46E5;
  color: white;
  border: none;
  margin-left: 8px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background-color 0.3s;
}

.send-button:hover:not(:disabled) {
  background-color: #4338ca;
}

.send-button:disabled {
  background-color: #adb5bd;
  cursor: not-allowed;
}

.send-icon {
  transform: rotate(90deg);
  font-size: 1.2rem;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes bounce {
  0%, 80%, 100% {
    transform: scale(0.8);
  }
  40% {
    transform: scale(1.2);
  }
}

@media (max-width: 768px) {
  .message {
    max-width: 85%;
  }
  
  .chat-interface {
    border-radius: 0;
    height: 100vh;
  }
}
</style>
