# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commonly Used Commands

### Services & Systemd Management
- **View LiteLLM logs:** `journalctl --user -u litellm -f`
- **View CCR logs:** `journalctl --user -u ccr -f`
- **Restart services:** `systemctl --user restart litellm ccr`
- **Get CCR Web UI Token:** `journalctl --user -u ccr -n 50 --no-pager | grep -o "http://127.0.0.1:[0-9]*/?ccr_web_token=[^ ]*" | tail -1`

### Testing Scripts
- **Test Gemini models directly:** `./tests/test-gemini.sh`
- **Test OpenRouter free models:** `./tests/test-openrouter.sh`

## High-Level Architecture & Smart Routing

This repository integrates **Claude Code** with multiple LLM providers (**Google Gemini API**, **OpenRouter**, etc.) via **Claude Code Router (CCR)** and **LiteLLM proxy**. 

### Smart Multi-Provider Routing Strategy
- **Primary / Fast Route (Direct Gemini):** Direct routing to Google Gemini API (e.g., `gemini-3.5-flash-lite`) handles regular interactive tasks, optimizing for speed and generous free-tier limits.
- **Thinking / Heavy Tasks (LiteLLM Proxy + Fallback Chain):** Complex or plan-mode requests (e.g., `/model opus` / `/model opusplan`) route through LiteLLM running locally on port `4000`. LiteLLM manages an automated fallback chain across high-tier Gemini models (`gemini-3.8-flash` down to `gemma-4-26b-a4b-it`) to maintain resilience during rate-limiting or outages.
- **Alternative Providers (OpenRouter):** Integrated via CCR/LiteLLM for supplementary models and specialized free-tier options (e.g., Cohere, Poolside, Nvidia Nemotron).

### Configuration Storage
- **CCR Config:** Stored in a local SQLite database and managed via the CCR web UI.
- **LiteLLM Config & Secrets:** Defined in `litellm/litellm.yaml` and secured under `~/.config/litellm/env` (`chmod 600`).
