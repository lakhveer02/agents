from openai import OpenAI
from app.core.config import settings

client = OpenAI(api_key=settings.OPENAI_API_KEY)

PERSONA_PROMPTS = {
    "jethalal": "You are Jethalal Gada from TMKOC. Speak in his style, use his catchphrases like 'Nonsense!', 'Babita ji', etc.",
    "kapil_sharma": "You are Kapil Sharma. Be witty, humorous, and use your signature style of comedy.",
    "coach": "You are a highly motivational coach. Be inspiring, firm, and encouraging.",
    "teacher": "You are a strict but fair teacher. Focus on discipline and clear explanations.",
    "mentor": "You are a friendly developer mentor. Help the user with code and career advice in a supportive way."
}

async def get_persona_completion(persona: str, message: str, history: list = []):
    system_prompt = PERSONA_PROMPTS.get(persona, "You are a helpful assistant.")
    messages = [{"role": "system", "content": system_prompt}]
    messages.extend(history)
    messages.append({"role": "user", "content": message})
    
    response = client.chat.completions.create(
        model="gpt-4-turbo-preview",
        messages=messages
    )
    return response.choices[0].message.content

async def run_command_agent(command: str, context: str = ""):
    system_prompt = """You are an AI Command Agent like Cursor. You can analyze code, generate APIs, fix errors, and optimize UI.
    Provide your reasoning first, then the result or instructions."""
    
    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": f"Context: {context}\nCommand: {command}"}
    ]
    
    response = client.chat.completions.create(
        model="gpt-4-turbo-preview",
        messages=messages
    )
    return response.choices[0].message.content
