#!/usr/bin/env python3
"""Usage: [PORT=8082] ./bench.py <model>   tg (t/s) for 3 short prompts + pp/tg for a ~2.7k-token long prompt."""
import json, os, sys, urllib.request, pathlib
env = pathlib.Path(__file__).resolve().parent / ".env"
KEY = next(l.split("=", 1)[1].strip() for l in env.read_text().splitlines() if l.startswith("LLAMA_CPP_API_KEY="))
M = sys.argv[1]
def q(content, n):
    r = urllib.request.Request("http://localhost:%s/v1/chat/completions" % os.environ.get("PORT", "8081"),
        json.dumps({"model": M, "messages": [{"role": "user", "content": content}], "max_tokens": n, "cache_prompt": False}).encode(),
        {"Authorization": "Bearer " + KEY, "Content-Type": "application/json"})
    return json.load(urllib.request.urlopen(r, timeout=1800))["timings"]
q("hi", 20)  # warm-up
tg = [round(q(p, 200)["predicted_per_second"], 1) for p in ["Explain the four seasons in detail", "Implement quicksort in Python and explain it", "Write a short story"]]
t = q("It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness. " * 100 + "\nSummarize the above in one sentence", 100)
print(M, "tg", tg, "long: n=%d pp=%d tg=%.1f" % (t["prompt_n"], t["prompt_per_second"], t["predicted_per_second"]))
