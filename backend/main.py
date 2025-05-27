from fastapi import FastAPI, HTTPException, Request, Body
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List, Union, Annotated
import os
import json
import uuid
from dotenv import load_dotenv
from datetime import datetime

# Load environment variables
load_dotenv()

# Import CrewAI components
from crewai import Agent, Task, Crew
from tools.contextual_input import ContextualInputModuleTool
from tools.sideboard_display import SideboardDisplayTool
from tasks.greeting_tasks import GreetingTasks
from crew.greeting_crew import GreetingCrew

app = FastAPI()

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Pydantic models
class ChatMessage(BaseModel):
    message: str
    conversation_id: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = Field(default_factory=dict)


class NameInput(BaseModel):
    name: str
    conversation_id: str
    metadata: Optional[Dict[str, Any]] = Field(default_factory=dict)


class UIComponentRequest(BaseModel):
    component_type: str = Field(..., description="Type of component to trigger")
    component_id: str = Field(..., description="Unique identifier for the component")
    data: Dict[str, Any] = Field(default_factory=dict)
    conversation_id: str


class UIComponentResponse(BaseModel):
    type: str
    id: str
    data: Dict[str, Any]


# Initialize CrewAI components
def create_greeting_agent():
    # Initialize tools
    input_tool = ContextualInputModuleTool()
    sideboard_tool = SideboardDisplayTool()

    return Agent(
        role="AI Concierge Greeter",
        goal="Welcome users, collect their name, and provide assistance",
        backstory="""You are a friendly AI that greets users, collects their name, 
        and provides helpful assistance. You're warm, professional, and guide users 
        through the initial interaction. When you need to show UI components, 
        use the appropriate tool and provide a clear JSON response.""",
        verbose=True,
        tools=[input_tool, sideboard_tool],
        allow_delegation=False,
    )


# Initialize components
greeting_agent = create_greeting_agent()
greeting_tasks = GreetingTasks(greeting_agent)
greeting_crew = GreetingCrew(greeting_agent, greeting_tasks)

# In-memory store for conversation state and UI components
conversation_states = {}
ui_components = {}


# API Endpoints
@app.get("/health")
async def health_check():
    return {"status": "healthy"}


@app.post("/api/chat")
async def chat(chat_data: ChatMessage):
    try:
        # Get or create conversation state
        conversation_id = chat_data.conversation_id or str(uuid.uuid4())
        if conversation_id not in conversation_states:
            conversation_states[conversation_id] = {
                "has_name": False,
                "name": None,
                "metadata": chat_data.metadata or {},
            }

        state = conversation_states[conversation_id]

        # Process the message with the crew
        response = greeting_crew.process_chat(chat_data.message, state)
        response["conversation_id"] = conversation_id

        return response

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/submit-name")
async def submit_name(name_data: NameInput):
    try:
        if (
            not name_data.conversation_id
            or name_data.conversation_id not in conversation_states
        ):
            raise HTTPException(status_code=400, detail="Invalid conversation ID")

        # Process the name with the crew
        response = greeting_crew.process_name(
            name_data.name, conversation_states[name_data.conversation_id]
        )
        response["conversation_id"] = name_data.conversation_id

        return response

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/ui/component-trigger")
async def trigger_component(component_data: UIComponentRequest):
    """
    Endpoint for triggering UI components from the agent.
    This is where CrewAI, via a tool, instructs the FastAPI app to send a specific UI component payload to the frontend.
    """
    try:
        if (
            not component_data.conversation_id
            or component_data.conversation_id not in conversation_states
        ):
            raise HTTPException(status_code=400, detail="Invalid conversation ID")

        # Store the component for future reference
        component_id = f"{component_data.component_type}_{component_data.component_id}"
        ui_components[component_id] = {
            "type": component_data.component_type,
            "id": component_id,
            "data": component_data.data,
            "conversation_id": component_data.conversation_id,
            "timestamp": str(datetime.utcnow()),
        }

        # Return the component data
        return {
            "type": component_data.component_type.upper(),
            "id": component_id,
            "data": component_data.data,
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# Add datetime import at the top
from datetime import datetime

if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
