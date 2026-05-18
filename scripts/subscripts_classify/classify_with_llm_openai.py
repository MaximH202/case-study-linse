from openai import OpenAI
from datetime import datetime, timezone
import json
import time

client = OpenAI()

def process_with_llm_openai(model_name, system_prompt, user_prompt, schema=None):

    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": user_prompt},
    ]

    if schema is not None:
        response_format={
            "type": "json_schema",
            "json_schema": {
                "name": "classifcation_result",
                "strict": True,
                "schema": schema
            }
        }

        llm_call_timestamp = datetime.now(timezone.utc).isoformat(timespec="seconds")
        start = time.time()
        response = client.chat.completions.create(
            model=model_name,
            messages=messages,
            response_format=response_format,
            reasoning_effort="minimal",
        )
        processing_time = time.time() - start

    else:
        llm_call_timestamp = datetime.now(timezone.utc).isoformat(timespec="seconds")
        start = time.time()
        response = client.chat.completions.create(
            model=model_name,
            messages=messages,
            reasoning_effort="minimal"
        )
        processing_time = time.time() - start

    answer = response.choices[0].message.content

    result = {
        "llm_result": answer,
        "llm_call_timestamp": llm_call_timestamp,
        "total_tokens": response.usage.total_tokens,
        "prompt_tokens": response.usage.prompt_tokens,
        "completion_tokens": response.usage.completion_tokens,
        "processing_time_seconds": processing_time,
    }
    return result


def process_rows_with_llm_openai(data, model, system_prompt, user_prompt_template, schema=None, log_fn=None):

    if schema is not None:
        schema = json.loads(schema)

    n_rows = len(data)
    log_fn(f"Starting: {n_rows} rows to process")

    elapsed_times = []

    for i, (index, row) in enumerate(data.iterrows()):

        user_prompt = user_prompt_template.format(text=row["text"])

        result = process_with_llm_openai(
            model_name=model,
            system_prompt=system_prompt,
            user_prompt=user_prompt,
            schema=schema
        )

        elapsed_times.append(result["processing_time_seconds"])
        avg_time = sum(elapsed_times) / len(elapsed_times)
        remaining = avg_time * (n_rows - (i + 1))
        log_fn(f"Row {i + 1}/{n_rows} done in {result['processing_time_seconds']:.1f}s — est. {remaining:.0f}s remaining")

        data.at[index, "llm_result"] = result["llm_result"]
        data.at[index, "llm_call_timestamp"] = result["llm_call_timestamp"]
        data.at[index, "total_tokens"] = result["total_tokens"]
        data.at[index, "prompt_tokens"] = result["prompt_tokens"]
        data.at[index, "completion_tokens"] = result["completion_tokens"]
        data.at[index, "processing_time_seconds"] = result["processing_time_seconds"]
        data.at[index, "model_used"] = model

    total = sum(elapsed_times)
    log_fn(f"Done: {n_rows} rows processed in {total:.1f}s total ({total / n_rows:.1f}s avg)")
    return data.to_dict("list")