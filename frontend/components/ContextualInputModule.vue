<template>
  <div class="contextual-input-overlay" v-if="isActive">
    <div class="contextual-input-container" :class="{ 'active': isActive }">
      <div class="module-header">
        <h3>{{ title }}</h3>
        <button class="close-button" @click="cancel" v-if="allowCancel">✕</button>
      </div>
      
      <div class="module-description" v-if="description">
        {{ description }}
      </div>
      
      <div class="input-fields">
        <!-- Text input (default) -->
        <div v-if="inputType === 'text'" class="input-field">
          <label :for="inputId">{{ inputLabel }}</label>
          <input 
            :id="inputId" 
            type="text" 
            v-model="inputValue" 
            :placeholder="placeholder"
            @keydown.enter="save"
          />
        </div>
        
        <!-- Textarea input -->
        <div v-else-if="inputType === 'textarea'" class="input-field">
          <label :for="inputId">{{ inputLabel }}</label>
          <textarea 
            :id="inputId" 
            v-model="inputValue" 
            :placeholder="placeholder"
            rows="4"
          ></textarea>
        </div>
        
        <!-- Select input -->
        <div v-else-if="inputType === 'select'" class="input-field">
          <label :for="inputId">{{ inputLabel }}</label>
          <select :id="inputId" v-model="inputValue">
            <option v-for="option in options" :key="option.value" :value="option.value">
              {{ option.label }}
            </option>
          </select>
        </div>
        
        <!-- Radio buttons -->
        <div v-else-if="inputType === 'radio'" class="input-field radio-group">
          <label>{{ inputLabel }}</label>
          <div class="radio-options">
            <div v-for="option in options" :key="option.value" class="radio-option">
              <input 
                type="radio" 
                :id="`${inputId}_${option.value}`" 
                :name="inputId" 
                :value="option.value" 
                v-model="inputValue"
              />
              <label :for="`${inputId}_${option.value}`">{{ option.label }}</label>
            </div>
          </div>
        </div>
        
        <!-- Checkbox group -->
        <div v-else-if="inputType === 'checkbox'" class="input-field checkbox-group">
          <label>{{ inputLabel }}</label>
          <div class="checkbox-options">
            <div v-for="option in options" :key="option.value" class="checkbox-option">
              <input 
                type="checkbox" 
                :id="`${inputId}_${option.value}`" 
                :value="option.value" 
                v-model="checkboxValues"
              />
              <label :for="`${inputId}_${option.value}`">{{ option.label }}</label>
            </div>
          </div>
        </div>
      </div>
      
      <div class="validation-error" v-if="validationError">
        {{ validationError }}
      </div>
      
      <div class="action-buttons">
        <button class="cancel-button" @click="cancel" v-if="allowCancel">Cancel</button>
        <button 
          class="save-button" 
          @click="save" 
          :disabled="!isValid || isSaving"
        >
          <span v-if="isSaving" class="loading-spinner"></span>
          <span v-else>{{ saveButtonText }}</span>
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import { useConversationStore } from '~/composables/useConversationStore';

// Props
const props = defineProps({
  componentId: {
    type: String,
    required: true
  },
  title: {
    type: String,
    default: 'Input Required'
  },
  description: {
    type: String,
    default: ''
  },
  inputType: {
    type: String,
    default: 'text',
    validator: (value) => ['text', 'textarea', 'select', 'radio', 'checkbox'].includes(value)
  },
  inputLabel: {
    type: String,
    default: 'Please enter your response:'
  },
  placeholder: {
    type: String,
    default: ''
  },
  options: {
    type: Array,
    default: () => []
  },
  required: {
    type: Boolean,
    default: true
  },
  allowCancel: {
    type: Boolean,
    default: true
  },
  saveButtonText: {
    type: String,
    default: 'Save'
  },
  validationRules: {
    type: Object,
    default: () => ({})
  }
});

// State
const conversationStore = useConversationStore();
const isActive = computed(() => {
  const activeComponent = conversationStore.activeComponent;
  return activeComponent && activeComponent.id === props.componentId;
});
const inputValue = ref('');
const checkboxValues = ref([]);
const validationError = ref('');
const isSaving = ref(false);
const inputId = computed(() => `input_${props.componentId}`);

// Computed
const isValid = computed(() => {
  if (props.required) {
    if (props.inputType === 'checkbox') {
      return checkboxValues.value.length > 0;
    } else {
      return !!inputValue.value;
    }
  }
  return true;
});

// Methods
const validate = () => {
  validationError.value = '';
  
  if (props.required && !isValid.value) {
    validationError.value = 'This field is required';
    return false;
  }
  
  // Custom validation rules can be added here
  if (props.validationRules.minLength && inputValue.value.length < props.validationRules.minLength) {
    validationError.value = `Minimum length is ${props.validationRules.minLength} characters`;
    return false;
  }
  
  if (props.validationRules.maxLength && inputValue.value.length > props.validationRules.maxLength) {
    validationError.value = `Maximum length is ${props.validationRules.maxLength} characters`;
    return false;
  }
  
  return true;
};

const save = async () => {
  if (!validate()) return;
  
  isSaving.value = true;
  
  try {
    // Prepare data for submission
    const submissionData = {
      [props.inputType === 'checkbox' ? 'values' : 'value']: 
        props.inputType === 'checkbox' ? checkboxValues.value : inputValue.value,
      component_id: props.componentId,
      conversation_id: conversationStore.conversationId
    };
    
    // For the name input specifically
    if (props.componentId === 'name_input') {
      const response = await $fetch('/api/submit-name', {
        method: 'POST',
        body: {
          name: inputValue.value,
          conversation_id: conversationStore.conversationId
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
      
      // Handle sideboard updates if present
      if (response.sideboard_display_id) {
        conversationStore.updateSideboard(response.sideboard_display_id, response.sideboard_data);
      }
    } else {
      // Generic component submission
      const response = await $fetch('/api/ui/component-submit', {
        method: 'POST',
        body: submissionData
      });
      
      // Process response as needed
      console.log('Component submission response:', response);
    }
    
    // Clear the active component
    conversationStore.clearActiveComponent();
    
    // Reset form
    inputValue.value = '';
    checkboxValues.value = [];
    
  } catch (error) {
    console.error('Error submitting input:', error);
    validationError.value = 'An error occurred while saving. Please try again.';
  } finally {
    isSaving.value = false;
  }
};

const cancel = () => {
  if (!props.allowCancel) return;
  
  // Clear the active component
  conversationStore.clearActiveComponent();
  
  // Reset form
  inputValue.value = '';
  checkboxValues.value = [];
  validationError.value = '';
};

// Focus the input field when component becomes active
watch(isActive, (newValue) => {
  if (newValue) {
    setTimeout(() => {
      const inputElement = document.getElementById(inputId.value);
      if (inputElement) {
        inputElement.focus();
      }
    }, 100);
  }
});

// Initialize with any default values from the store
onMounted(() => {
  const activeComponent = conversationStore.activeComponent;
  if (activeComponent && activeComponent.id === props.componentId && activeComponent.data) {
    if (activeComponent.data.defaultValue) {
      inputValue.value = activeComponent.data.defaultValue;
    }
    if (activeComponent.data.options) {
      props.options = activeComponent.data.options;
    }
  }
});
</script>

<style scoped>
.contextual-input-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  animation: fadeIn 0.3s ease-in-out;
}

.contextual-input-container {
  background-color: white;
  border-radius: 12px;
  width: 90%;
  max-width: 500px;
  padding: 24px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
  animation: slideUp 0.3s ease-in-out;
}

.module-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.module-header h3 {
  margin: 0;
  font-size: 1.5rem;
  color: #212529;
}

.close-button {
  background: none;
  border: none;
  font-size: 1.2rem;
  color: #adb5bd;
  cursor: pointer;
  padding: 4px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background-color 0.2s;
}

.close-button:hover {
  background-color: #f1f3f5;
  color: #495057;
}

.module-description {
  margin-bottom: 20px;
  color: #6c757d;
  line-height: 1.5;
}

.input-fields {
  margin-bottom: 24px;
}

.input-field {
  margin-bottom: 16px;
}

.input-field label {
  display: block;
  margin-bottom: 8px;
  font-weight: 500;
  color: #495057;
}

.input-field input[type="text"],
.input-field textarea,
.input-field select {
  width: 100%;
  padding: 12px;
  border: 1px solid #ced4da;
  border-radius: 6px;
  font-size: 1rem;
  font-family: inherit;
  transition: border-color 0.2s;
}

.input-field input[type="text"]:focus,
.input-field textarea:focus,
.input-field select:focus {
  border-color: #4F46E5;
  outline: none;
}

.radio-group,
.checkbox-group {
  margin-bottom: 16px;
}

.radio-options,
.checkbox-options {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.radio-option,
.checkbox-option {
  display: flex;
  align-items: center;
  gap: 8px;
}

.radio-option input,
.checkbox-option input {
  margin: 0;
}

.validation-error {
  color: #e03131;
  font-size: 0.9rem;
  margin-bottom: 16px;
  animation: shake 0.5s ease-in-out;
}

.action-buttons {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
}

.cancel-button,
.save-button {
  padding: 10px 20px;
  border-radius: 6px;
  font-size: 1rem;
  cursor: pointer;
  transition: background-color 0.2s;
}

.cancel-button {
  background-color: #f1f3f5;
  color: #495057;
  border: 1px solid #ced4da;
}

.cancel-button:hover {
  background-color: #e9ecef;
}

.save-button {
  background-color: #4F46E5;
  color: white;
  border: none;
  min-width: 100px;
  position: relative;
}

.save-button:hover:not(:disabled) {
  background-color: #4338ca;
}

.save-button:disabled {
  background-color: #adb5bd;
  cursor: not-allowed;
}

.loading-spinner {
  display: inline-block;
  width: 16px;
  height: 16px;
  border: 2px solid rgba(255, 255, 255, 0.3);
  border-radius: 50%;
  border-top-color: white;
  animation: spin 1s linear infinite;
}

@keyframes fadeIn {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}

@keyframes slideUp {
  from {
    transform: translateY(20px);
    opacity: 0;
  }
  to {
    transform: translateY(0);
    opacity: 1;
  }
}

@keyframes shake {
  0%, 100% {
    transform: translateX(0);
  }
  10%, 30%, 50%, 70%, 90% {
    transform: translateX(-5px);
  }
  20%, 40%, 60%, 80% {
    transform: translateX(5px);
  }
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}
</style>
