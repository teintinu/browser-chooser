# Browser Chooser

A professional, high-performance, and AI-powered browser router for macOS. It acts as a system-wide agent that intercepts URL opening requests and routes them to specific browsers based on intelligent rules or manual selection with smart pattern suggestions.

---

## 🚀 Key Features

*   **Intelligent URL Interception**: Deeply integrated with macOS as a protocol handler for `http` and `https`.
*   **AI-Assisted Rule Creation**: Real-time integration with local LLMs (Ollama, LM Studio) to suggest optimal Regex routing patterns.
*   **Ephemeral Design (Zero UI)**:
    *   **Silent Routing**: Matched URLs are routed instantly in the background without showing any windows.
    *   **Auto-Termination**: The app closes automatically after forwarding a URL, ensuring zero background resource consumption.
*   **Smart Selection UI**:
    *   **Memory**: Remembers your last selected browser for faster manual routing.
    *   **Live Validation**: Real-time Regex validation ensures your patterns match the intended URL before saving.
    *   **Editable Test URL**: Modify the displayed URL in the rule configuration panel to test broad patterns without changing the actual destination.
    *   **Organized Management**: Browser rules are automatically grouped by target browser for clarity.

---

## 🛠 Automation & Workflows

The project is designed for developer efficiency with three core automation scripts:

- **`./build.sh`**: Compiles the native binary, generates the `.app` bundle, installs it to `~/Applications`, and registers the app with macOS.
- **`./run.sh`**: Safely launches the agent.
- **`./test.sh`**: The ultimate testing tool. 
    - Use `./test.sh` for an interactive menu of common test scenarios (GitHub, Slack, AWS, Linear, etc.).
    - Use `./test.sh <URL>` for immediate direct testing.

---

## 📋 Technical Specifications

*   **Technology Stack**: Native Swift 5.10+, SwiftUI, and AppKit.
*   **Event Handling**: Leverages Apple Events (`kAEGetURL`) via `NSAppleEventManager` for precise link interception.
*   **Architecture**:
    *   **Router**: Centralized logic for matching, routing, and app lifecycle management.
    *   **Storage**: Atomic local persistence using JSON files in `Application Support`.
    *   **AI Backend**: Compatible with any OpenAI-style local API.
*   **Requirements**: Must be set as the **Default Browser** in macOS System Settings to intercept links from external apps.

---

## ⚙️ How it Works

1.  **Intercept**: A link is clicked in any macOS app (Mail, Slack, Terminal).
2.  **Match**: The Router checks against saved Regex rules.
3.  **Action**:
    *   **If Match found**: URL is forwarded to the specific browser, and Teintinu terminates immediately.
    *   **If No Match**: The **Selector Window** appears.
4.  **Selection & Rule Creation**:
    *   Choose a browser (last choice is auto-selected).
    *   Optionally check "Always open this type of link".
    *   The **Rule Panel** provides 15-20 AI-generated Regex patterns.
    *   **Test & Validate**: Edit the "Test URL" to ensure your Regex works for multiple cases (subdomains, different paths, etc.) before confirming.
    *   Confirm the rule; the app saves it, opens the original link, and terminates.

---
*Developed with a focus on speed, privacy, and minimalist UX.*
