import { ref, reactive } from 'vue';

export const useConversationStore = () => {
  // Singleton pattern to ensure the same store is used across components
  if (useConversationStore._instance) {
    return useConversationStore._instance;
  }

  // State
  const conversationId = ref(null);
  const messages = ref([]);
  const exchanges = ref([]);
  const activeComponent = ref(null);
  const activeSideboardContent = ref(null);
  const sideboardHistory = ref([]);

  // Methods
  const setConversationId = (id) => {
    conversationId.value = id;
  };

  const addMessage = (message) => {
    messages.value.push(message);
    
    // Group messages into exchanges
    const lastExchange = exchanges.value[exchanges.value.length - 1];
    
    if (!lastExchange || lastExchange.isComplete) {
      // Start a new exchange
      exchanges.value.push({
        id: `exchange_${Date.now()}`,
        title: message.sender === 'ai' ? 'AI Greeting' : 'User Inquiry',
        timestamp: message.timestamp,
        messages: [message],
        isComplete: false
      });
    } else {
      // Add to existing exchange
      lastExchange.messages.push(message);
      
      // Mark exchange as complete if user message followed by AI message
      if (
        lastExchange.messages.length >= 2 &&
        lastExchange.messages[lastExchange.messages.length - 1].sender === 'ai' &&
        lastExchange.messages[lastExchange.messages.length - 2].sender === 'user'
      ) {
        lastExchange.isComplete = true;
      }
    }
  };

  const setActiveComponent = (componentId, data = {}) => {
    console.log('Setting active component:', componentId, data);
    activeComponent.value = {
      id: componentId,
      type: data.type || 'contextual_input',
      data: data
    };
  };

  const clearActiveComponent = () => {
    activeComponent.value = null;
  };

  const updateSideboard = (displayId, data) => {
    console.log('Updating sideboard:', displayId, data);
    
    // Create sideboard content
    const sideboardContent = {
      id: displayId,
      title: data.title || 'Information',
      content: data.content || '',
      timestamp: new Date()
    };
    
    // Set as active content
    activeSideboardContent.value = sideboardContent;
    
    // Add to history
    sideboardHistory.value.unshift(sideboardContent);
    
    // Limit history size
    if (sideboardHistory.value.length > 10) {
      sideboardHistory.value = sideboardHistory.value.slice(0, 10);
    }
    
    // Associate with current exchange if one exists
    const lastExchange = exchanges.value[exchanges.value.length - 1];
    if (lastExchange) {
      lastExchange.sideboardContent = sideboardContent;
      console.log('Associated sideboard content with exchange:', lastExchange.id);
    }
    
    return sideboardContent;
  };

  const setActiveSideboardContent = (content) => {
    activeSideboardContent.value = content;
  };

  const clearConversation = () => {
    messages.value = [];
    exchanges.value = [];
    activeComponent.value = null;
    activeSideboardContent.value = null;
    // We don't clear sideboard history or conversation ID
  };

  // Create the store instance
  const store = {
    // State
    conversationId,
    messages,
    exchanges,
    activeComponent,
    activeSideboardContent,
    sideboardHistory,
    
    // Methods
    setConversationId,
    addMessage,
    setActiveComponent,
    clearActiveComponent,
    updateSideboard,
    setActiveSideboardContent,
    clearConversation
  };

  // Save the instance
  useConversationStore._instance = store;
  
  return store;
};
