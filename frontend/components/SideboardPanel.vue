<template>
  <div class="sideboard-container" :class="{ 'collapsed': isCollapsed }">
    <!-- Toggle button -->
    <button class="toggle-button" @click="toggleSideboard">
      {{ isCollapsed ? '◀' : '▶' }}
    </button>
    
    <div class="sideboard-content">
      <!-- Header -->
      <div class="sideboard-header">
        <h2>Sideboard</h2>
      </div>
      
      <!-- Active display area -->
      <div class="active-display-area">
        <div v-if="activeSideboardContent" class="sideboard-item active">
          <h3>{{ activeSideboardContent.title }}</h3>
          <div class="sideboard-item-content" v-html="activeSideboardContent.content"></div>
        </div>
        <div v-else class="empty-state">
          No active content to display
        </div>
      </div>
      
      <!-- History section -->
      <div class="sideboard-history">
        <h3>History</h3>
        <div v-if="sideboardHistory.length > 0" class="history-list">
          <div 
            v-for="(item, index) in sideboardHistory" 
            :key="index"
            class="history-item"
            @click="setActiveSideboardContent(item)"
          >
            <div class="history-item-title">{{ item.title }}</div>
            <div class="history-item-timestamp">{{ formatTimestamp(item.timestamp) }}</div>
          </div>
        </div>
        <div v-else class="empty-state">
          No history items yet
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue';
import { useConversationStore } from '~/composables/useConversationStore';

// State
const isCollapsed = ref(false);
const conversationStore = useConversationStore();

// Computed properties
const activeSideboardContent = computed(() => conversationStore.activeSideboardContent);
const sideboardHistory = computed(() => conversationStore.sideboardHistory);

// Methods
const toggleSideboard = () => {
  isCollapsed.value = !isCollapsed.value;
};

const setActiveSideboardContent = (item) => {
  conversationStore.setActiveSideboardContent(item);
};

const formatTimestamp = (timestamp) => {
  const date = new Date(timestamp);
  return date.toLocaleString([], { 
    month: 'short', 
    day: 'numeric', 
    hour: '2-digit', 
    minute: '2-digit' 
  });
};
</script>

<style scoped>
.sideboard-container {
  position: relative;
  width: 320px;
  height: 100%;
  background-color: #f8f9fa;
  border-left: 1px solid #dee2e6;
  transition: transform 0.3s ease-in-out;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.sideboard-container.collapsed {
  transform: translateX(calc(100% - 30px));
}

.toggle-button {
  position: absolute;
  left: 0;
  top: 50%;
  transform: translateY(-50%);
  width: 30px;
  height: 60px;
  background-color: #4F46E5;
  color: white;
  border: none;
  border-top-left-radius: 8px;
  border-bottom-left-radius: 8px;
  cursor: pointer;
  z-index: 10;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1rem;
  box-shadow: -2px 0 5px rgba(0, 0, 0, 0.1);
}

.sideboard-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  padding: 16px;
  overflow: hidden;
}

.sideboard-header {
  padding-bottom: 16px;
  border-bottom: 1px solid #dee2e6;
  margin-bottom: 16px;
}

.sideboard-header h2 {
  margin: 0;
  font-size: 1.5rem;
  color: #212529;
}

.active-display-area {
  flex: 1;
  overflow-y: auto;
  padding: 16px;
  background-color: white;
  border-radius: 8px;
  margin-bottom: 16px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
}

.sideboard-item {
  animation: fadeIn 0.3s ease-in-out;
}

.sideboard-item h3 {
  margin-top: 0;
  margin-bottom: 12px;
  font-size: 1.2rem;
  color: #4F46E5;
}

.sideboard-item-content {
  line-height: 1.6;
  color: #495057;
}

.sideboard-history {
  max-height: 30%;
  overflow-y: auto;
}

.sideboard-history h3 {
  margin-top: 0;
  margin-bottom: 12px;
  font-size: 1.2rem;
  color: #212529;
}

.history-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.history-item {
  padding: 12px;
  background-color: white;
  border-radius: 8px;
  cursor: pointer;
  transition: background-color 0.2s;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
}

.history-item:hover {
  background-color: #f1f3f5;
}

.history-item-title {
  font-weight: 500;
  margin-bottom: 4px;
  color: #343a40;
}

.history-item-timestamp {
  font-size: 0.8rem;
  color: #868e96;
}

.empty-state {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 100px;
  color: #adb5bd;
  font-style: italic;
  text-align: center;
}

@keyframes fadeIn {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}

@media (max-width: 768px) {
  .sideboard-container {
    position: fixed;
    top: 0;
    right: 0;
    height: 100vh;
    z-index: 1000;
  }
  
  .sideboard-container.collapsed {
    transform: translateX(100%);
  }
  
  .toggle-button {
    left: -30px;
  }
}
</style>
