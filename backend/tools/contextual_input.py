from typing import Dict, Any, Optional
from pydantic import BaseModel, Field
from crewai.tools import BaseTool


class ContextualInputToolInput(BaseModel):
    """Input for ContextualInputModuleTool."""

    input_type: str = Field(
        ..., description="Type of input (e.g., 'text', 'email', 'number')"
    )
    label: str = Field(..., description="Label to display for the input")
    required: bool = Field(True, description="Whether the input is required")
    placeholder: Optional[str] = Field(
        None, description="Placeholder text for the input"
    )


class ContextualInputModuleTool(BaseTool):
    """Tool for triggering contextual input UI components."""

    name: str = "contextual_input_tool"
    description: str = (
        "Use this tool when you need to collect specific information from the user via a form input."
    )
    args_schema: type[BaseModel] = ContextualInputToolInput

    def _run(
        self,
        input_type: str,
        label: str,
        required: bool = True,
        placeholder: str = None,
    ) -> Dict[str, Any]:
        """Trigger a contextual input UI component.

        Args:
            input_type: Type of input (e.g., 'text', 'email', 'number')
            label: Label to display for the input
            required: Whether the input is required
            placeholder: Placeholder text for the input

        Returns:
            Dict containing the UI component configuration
        """
        return {
            "type": "CONTEXTUAL_INPUT",
            "id": f"input_{input_type}_{label.lower().replace(' ', '_')}",
            "data": {
                "input_type": input_type,
                "label": label,
                "required": required,
                "placeholder": placeholder or f"Please enter {label.lower()}",
            },
        }
