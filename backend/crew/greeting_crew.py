from crewai import Crew
from typing import Dict, Any, List, Optional
import json

class GreetingCrew:
    def __init__(self, agent, tasks):
        self.agent = agent
        self.tasks = tasks
        
    def process_chat(self, message: str, conversation_state: Dict[str, Any]) -> Dict[str, Any]:
        """Process a chat message and return the response."""
        try:
            # Create tasks based on conversation state
            if not conversation_state.get("has_name", False):
                task = self.tasks.greet_user()
            else:
                task = self.tasks.handle_general_chat(message)
            
            # Create and run the crew
            crew = Crew(
                agents=[self.agent],
                tasks=[task],
                verbose=True
            )
            
            # Execute the task
            result = crew.kickoff()
            
            # Process the result for UI components
            return self._process_crew_output(result, conversation_state)
            
        except Exception as e:
            return {
                "response": "I encountered an error processing your message.",
                "error": str(e)
            }
    
    def process_name(self, name: str, conversation_state: Dict[str, Any]) -> Dict[str, Any]:
        """Process the user's name and return the response."""
        try:
            # Update conversation state
            conversation_state.update({
                "has_name": True,
                "name": name.strip()
            })
            
            # Create and run the name acknowledgment task
            task = self.tasks.acknowledge_name(name)
            crew = Crew(
                agents=[self.agent],
                tasks=[task],
                verbose=True
            )
            
            result = crew.kickoff()
            return self._process_crew_output(result, conversation_state)
            
        except Exception as e:
            return {
                "response": "I encountered an error processing your name.",
                "error": str(e)
            }
    
    def _process_crew_output(self, result: str, conversation_state: Dict[str, Any]) -> Dict[str, Any]:
        """Process the crew's output and extract UI components."""
        response = {
            "response": result,
            "conversation_state": conversation_state
        }
        
        # Try to parse any JSON in the result
        try:
            # Look for JSON objects in the result
            if '{' in result and '}' in result:
                start = result.find('{')
                end = result.rfind('}') + 1
                json_str = result[start:end]
                data = json.loads(json_str)
                
                if isinstance(data, dict):
                    if 'type' in data and 'data' in data:
                        response["ui_components"] = [data]
                        response["response"] = result[:start] + result[end+1:].strip()
        except (json.JSONDecodeError, AttributeError):
            pass
            
        return response
