from typing import Dict, Any, List, Optional
from pydantic import BaseModel, Field
from crewai.tools import BaseTool

class SideboardContent(BaseModel):
    """Model for sideboard content."""
    title: str = Field(..., description="Title of the sideboard content")
    content: str = Field(..., description="Main content to display")
    type: str = Field("text", description="Type of content (text, markdown, html, etc.)")
    actions: Optional[List[Dict[str, Any]]] = Field(
        None, 
        description="List of action buttons/links to display"
    )

class SideboardDisplayTool(BaseTool):
    """Tool for updating the sideboard display."""
    name: str = "update_sideboard"
    description: str = "Use this tool to update the sideboard with relevant information or actions."
    args_schema: type[BaseModel] = SideboardContent
    
    def _run(
        self, 
        title: str, 
        content: str, 
        content_type: str = "text",
        actions: Optional[List[Dict[str, Any]]] = None
    ) -> Dict[str, Any]:
        """Update the sideboard with the given content.
        
        Args:
            title: Title of the sideboard content
            content: Main content to display
            content_type: Type of content (text, markdown, html, etc.)
            actions: List of action buttons/links to display
            
        Returns:
            Dict containing the sideboard configuration
        """
        return {
            "type": "SIDEBOARD_UPDATE",
            "data": {
                "title": title,
                "content": content,
                "content_type": content_type,
                "actions": actions or []
            }
        }
