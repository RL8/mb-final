<template>
  <div class="exchange-unit" :class="{ 'collapsed': isCollapsed }">
    <!-- Header with summary and toggle -->
    <div class="exchange-header" @click="toggleCollapse">
      <div class="exchange-summary">
        <div class="exchange-icon">
          <span v-if="isCollapsed">▶</span>
          <span v-else>▼</span>
        </div>
        <div class="exchange-title">
          {{ exchange.title || 'Exchange' }}
        </div>
        <div class="exchange-timestamp">
          {{ formatTimestamp(exchange.timestamp) }}
        </div>
      </div>
      
      <!-- Sideboard mini preview (always visible) -->
      <div class="sideboard-mini-preview" v-if="exchange.sideboardContent">
        <div class="mini-preview-icon">📋</div>
        <div class="mini-preview-title">{{ exchange.sideboardContent.title }}</div>
      </div>
    </div>
    
    <!-- Collapsible content -->
    <div class="exchange-content" v-if="!isCollapsed">
      <!-- Messages in this exchange -->
      <div 
        v-for="(message, index) in exchange.messages" 
        :key="index" 
        :class="['exchange-message', message.sender === 'ai' ? 'ai-message' : 'user-message']"
      >
        <div class="message-sender">{{ message.sender === 'ai' ? 'AI' : 'You' }}</div>
        <div class="message-content">{{ message.content }}</div>
      </div>
      
      <!-- Sideboard content related to this exchange -->
      <div class="exchange-sideboard" v-if="exchange.sideboardContent">
        <div class="sideboard-header">
          <div class="sideboard-icon">📋</div>
          <div class="sideboard-title">{{ exchange.sideboardContent.title }}</div>
        </div>
        <div class="sideboard-content" v-html="exchange.sideboardContent.content"></div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue';

// Props
const props = defineProps({
  exchange: {
    type: Object,
    required: true,
    validator: (obj) => {
      return obj.messages && Array.isArray(obj.messages) && obj.timestamp;
    }
  },
  initialCollapsed: {
    type: Boolean,
    default: false
  }
});

// State
const isCollapsed = ref(props.initialCollapsed);

// Methods
const toggleCollapse = () => {
  isCollapsed.value = !isCollapsed.value;
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
.exchange-unit {
  border: 1px solid #dee2e6;
  border-radius: 8px;
  margin-bottom: 16px;
  background-color: white;
  overflow: hidden;
  transition: box-shadow 0.2s;
}

.exchange-unit:hover {
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
}

.exchange-header {
  padding: 12px 16px;
  background-color: #f8f9fa;
  cursor: pointer;
  display: flex;
  justify-content: space-between;
  align-items: center;
  user-select: none;
}

.exchange-summary {
  display: flex;
  align-items: center;
  gap: 8px;
}

.exchange-icon {
  color: #4F46E5;
  font-size: 0.8rem;
  width: 16px;
  height: 16px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.exchange-title {
  font-weight: 500;
  color: #212529;
}

.exchange-timestamp {
  font-size: 0.8rem;
  color: #6c757d;
  margin-left: 8px;
}

.sideboard-mini-preview {
  display: flex;
  align-items: center;
  gap: 8px;
  background-color: #e9ecef;
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 0.8rem;
}

.mini-preview-icon {
  font-size: 1rem;
}

.mini-preview-title {
  color: #495057;
  max-width: 150px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.exchange-content {
  padding: 16px;
  border-top: 1px solid #dee2e6;
  animation: expandContent 0.3s ease-in-out;
}

.exchange-message {
  margin-bottom: 12px;
  padding: 12px;
  border-radius: 8px;
  position: relative;
}

.exchange-message:last-child {
  margin-bottom: 16px;
}

.message-sender {
  font-weight: 500;
  margin-bottom: 4px;
}

.message-content {
  line-height: 1.5;
}

.ai-message {
  background-color: #f1f3f5;
}

.ai-message .message-sender {
  color: #4F46E5;
}

.user-message {
  background-color: #e7f5ff;
}

.user-message .message-sender {
  color: #1971c2;
}

.exchange-sideboard {
  margin-top: 16px;
  padding: 16px;
  background-color: #f8f9fa;
  border-radius: 8px;
  border: 1px dashed #ced4da;
}

.sideboard-header {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 12px;
}

.sideboard-icon {
  font-size: 1.2rem;
}

.sideboard-title {
  font-weight: 500;
  color: #212529;
}

.sideboard-content {
  color: #495057;
  line-height: 1.6;
}

@keyframes expandContent {
  from {
    opacity: 0;
    max-height: 0;
  }
  to {
    opacity: 1;
    max-height: 1000px;
  }
}

@media (max-width: 768px) {
  .sideboard-mini-preview {
    display: none;
  }
}
</style>
