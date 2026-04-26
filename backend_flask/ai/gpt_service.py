import requests
import os

def generate_clinical_insight(adherence):
    try:
        api_key = os.environ.get("GROQ_API_KEY")

        if not api_key:
            raise ValueError("Missing GROQ_API_KEY in environment")

        url = "https://api.groq.com/openai/v1/chat/completions"

        headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        }

        prompt = f"""
Patient adherence rate: {adherence}%.

Provide a concise clinical insight in a natural, doctor-like tone.
Briefly interpret the adherence level, mention any potential clinical concern, and include one practical recommendation if appropriate.
Keep it to 2–3 sentences maximum and write as one smooth paragraph.
Do NOT use bullet points, sections, markdown, or formatting.
Do NOT repeat the percentage.
Avoid unnecessary detail.
"""

        payload = {
            "model": "llama-3.1-8b-instant",
            "messages": [
                {"role": "system", "content": "You are a clinical adherence assistant."},
                {"role": "user", "content": prompt},
            ],
            "temperature": 0.3,
            "max_tokens": 120,
        }

        response = requests.post(url, headers=headers, json=payload, timeout=30)
        response.raise_for_status()

        data = response.json()
        text = data["choices"][0]["message"]["content"].strip()

        text = text.replace("**", "")
        text = text.replace("Clinical Insight:", "")
        text = text.replace("Recommended Action:", "")
        text = " ".join(text.split())

        return text.strip()

    except Exception as e:
        print("AI ERROR:", e)

        if adherence >= 90:
            return "Adherence appears strong, with low immediate concern. Continue routine monitoring and reinforce the current medication plan."
        elif adherence >= 75:
            return "Adherence is fairly stable but still leaves room for improvement. Reviewing daily medication routines and possible barriers may help maintain consistency."
        elif adherence >= 60:
            return "Adherence is below optimal and may begin to affect treatment effectiveness. A follow-up to identify barriers and simplify the routine may be helpful."
        else:
            return "Adherence is concerning and may place treatment outcomes at risk. Prompt follow-up and targeted support are recommended."


# history = list of {"role": "user"|"assistant", "content": "..."}
def generate_chat_response(history):
    try:
        api_key = os.environ.get("GROQ_API_KEY")

        if not api_key:
            raise ValueError("Missing GROQ_API_KEY in environment")

        url = "https://api.groq.com/openai/v1/chat/completions"

        headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        }

        system_prompt = (
            "You are a clinical assistant embedded in a medication adherence "
            "monitoring system. You help doctors understand patient medication "
            "adherence, missed doses, risk levels, and clinical recommendations. "
            "You must ONLY answer questions related to medications, adherence, "
            "patient health, or clinical decisions. "
            "If asked about anything unrelated (e.g. sports, coding, general "
            "knowledge), politely decline and redirect to medication topics. "
            "Keep responses concise — 3 sentences max unless more detail is "
            "genuinely needed. Do not use markdown, bullet points, or formatting."
        )

        messages = [{"role": "system", "content": system_prompt}] + history

        payload = {
            "model": "llama-3.1-8b-instant",
            "messages": messages,
            "temperature": 0.3,
            "max_tokens": 300,
        }

        response = requests.post(url, headers=headers, json=payload, timeout=30)
        response.raise_for_status()

        data = response.json()
        return data["choices"][0]["message"]["content"].strip()

    except Exception as e:
        print("AI CHAT ERROR:", e)
        return "Unable to generate a response right now. Please try again."
