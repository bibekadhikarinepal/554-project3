#!/usr/bin/env python3
"""Show attribute-level drift from a saved plan.

Usage: terraform show -json drift.tfplan | python3 scripts/drift-attributes.py
"""
import json
import sys


def diff(before, after, path=""):
    if isinstance(before, dict) and isinstance(after, dict):
        for key in sorted(set(before) | set(after)):
            yield from diff(before.get(key), after.get(key), f"{path}.{key}")
    elif isinstance(before, list) and isinstance(after, list) and len(before) == len(after):
        for i, (b, a) in enumerate(zip(before, after)):
            yield from diff(b, a, f"{path}[{i}]")
    elif before != after:
        yield f"{path}: {json.dumps(before)[:80]} -> {json.dumps(after)[:80]}"


def is_normalization(before, after):
    empty = (None, [], {}, "", 0, False)
    return before in empty and after in empty


def main():
    plan = json.load(sys.stdin)
    drift = plan.get("resource_drift", [])
    if not drift:
        print("No drift: state matches the real objects.")
        return
    for item in drift:
        change = item["change"]
        print(f"{item['address']}  ({'/'.join(change['actions'])} outside Terraform)")
        for line in diff(change.get("before"), change.get("after")):
            print(f"    {line}")
    real = []
    for item in drift:
        stack = [(item["change"].get("before"), item["change"].get("after"))]
        while stack:
            b, a = stack.pop()
            if isinstance(b, dict) and isinstance(a, dict):
                stack.extend((b.get(k), a.get(k)) for k in set(b) | set(a))
            elif isinstance(b, list) and isinstance(a, list) and len(b) == len(a):
                stack.extend(zip(b, a))
            elif b != a and not is_normalization(b, a):
                real.append(item["address"])
                break
    if real:
        print(f"\nMeaningful drift on: {', '.join(sorted(set(real)))}")
    else:
        print("\nOnly empty-value normalization (null vs []/{}/0): no meaningful drift.")


if __name__ == "__main__":
    main()
