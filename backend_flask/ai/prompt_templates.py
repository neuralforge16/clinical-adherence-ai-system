def clinical_adherence_prompt(adherence):

    return f"""
You are a clinical decision support assistant.

A patient medication adherence rate is {adherence}%.

Explain briefly:

1) What this means clinically
2) Whether this is safe or risky
3) What a doctor should consider

Keep the answer short and professional.
"""