# Evidence

Plain-text output from my runs on 2026-11-26 (UTC).

- Lines starting with `$` are the commands I ran. The lines after each one are its output.
- Lines starting with `#` are my notes.
- Long output is shortened, and `[...]` marks where lines were removed.

| File | Requirement | What it shows |
|---|---|---|
| [01](01-init-fmt-validate.txt) | init, fmt, validate | All three succeed |
| [02](02-plan.txt) | plan | 6 to add, with the key settings (internal network, ports, env, volume) |
| [03](03-apply.txt) | apply | Creation order (Redis before API) and outputs |
| [04](04-http-test.txt) | HTTP test | Smoke test passes, Redis count matches, only the API has a host port, Redis has no internet access |
| [05](05-controlled-change.txt) | controlled change | `host_port` 8081 to 8082: saved plan as text (API replaced, `forces replacement`), apply, new endpoint works |
| [06](06-state-list.txt) | state list | Resources Terraform owns |
| [07](07-persistence-test.txt) | persistence test | API container replaced; Redis container and volume unchanged; count 12 to 13 |
| [08](08-destroy.txt) | destroy | All 6 resources removed; nothing left; volume deleted, images kept |
| [cs554/09](cs554/09-dev-test-environments.txt) | CS 554 dev/test | Same code, different names and ports, separate state files, workspace guard |
| [cs554/10](cs554/10-drift-experiment.txt) | CS 554 drift | Expected vs observed plan for two manual changes, and the recovery |

## Notes

- **07:** I ran this test twice. The first run lost the plan summary because of terminal colour codes, which is why the counts start at 11.
- **08:** I re-applied the stack and destroyed it again to get clean destroy output.
- **cs554/09:**
  - The `diff` of the two environment files was run again after I shortened the comments in those files. The values were not changed.
