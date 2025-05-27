from crewai import Task
from typing import Dict, Any, Optional


class GreetingTasks:
    def __init__(self, agent):
        self.agent = agent

    def greet_user(self) -> Task:
        return Task(
            description="""Greet the user and ask for their name. 
            Use the contextual_input_tool to request their name if not provided.""",
            agent=self.agent,
            expected_output="A warm greeting and a request for the user's name",
            async_execution=True,
        )

    def acknowledge_name(self, name: str) -> Task:
        return Task(
            description=f"""Acknowledge the user's name ({name}) and provide a welcome message. 
            Use the update_sideboard tool to show a welcome message.""",
            agent=self.agent,
            context=[f"User's name is: {name}"],
            expected_output="A personalized welcome message and sideboard update",
            async_execution=True,
        )

    def handle_general_chat(self, message: str) -> Task:
        return Task(
            description=f"""Respond to the user's message: {message}""",
            agent=self.agent,
            expected_output="A helpful and relevant response to the user's message",
            async_execution=True,
        )
