You can automate this by running the following one-liner command in your terminal:

```bash
curl -s https://github.com/ulyweb/proxmox/releases/download/myproxmox-v1.0.0/custom-prompt.sh | bash
```

Create a script named `custom-prompt.sh` with the following content and host it on a web server you control:

```bash
cat << 'EOF' >> ~/.bashrc
update_ps1() {
    PS1="\\[\\e[1;31m\\]\\u@\\h \\[\\e[1;33m\\][\\d \\t]\\[\\e[0m\\]\\n\\[\\e[1;32m\\]\\w\\[\\e[0m\\] [Load: $(cut -d ' ' -f1 /proc/loadavg)]\\n\\$ "
}
PROMPT_COMMAND=update_ps1
EOF
source ~/.bashrc
```

This way, you only run one command to set it up on any server.


---

Run this to install Starship and set it up:

```bash
curl -sS https://starship.rs/install.sh | sh

echo 'eval "$(starship init bash)"' >> ~/.bashrc
```

Then create a `~/.config/starship.toml` with fine-tuned configuration. I can prepare a complete Starship configuration for you, including load averages, memory, git info, and elegant styling. Let me know if you want me to generate that config file for you!

---

Got it — since you're working directly on a Proxmox host (which generally uses bash by default), the safest and most robust professional-grade option is to use **Liquidprompt**, which is lightweight, compatible with bash, and designed for administrators managing servers.

Here’s how to set it up:

1️⃣ Install dependencies:
```bash
apt update && apt install git -y
```

2️⃣ Clone Liquidprompt:
```bash
git clone https://github.com/nojhan/liquidprompt.git ~/.liquidprompt
```

3️⃣ Add to your `~/.bashrc`:
```bash
if [ -f "$HOME/.liquidprompt/liquidprompt" ]; then
    source "$HOME/.liquidprompt/liquidprompt"
fi
```

4️⃣ Reload:
```bash
source ~/.bashrc
```

Liquidprompt provides a clean, informative prompt with context-aware details like hostname, load, git info, and more — ideal for a Proxmox host environment.

---

Sure — here’s a one-liner command to set up Liquidprompt on your Proxmox host:

```bash
apt update && apt install git -y && git clone https://github.com/nojhan/liquidprompt.git ~/.liquidprompt && echo -e '\nif [ -f "$HOME/.liquidprompt/liquidprompt" ]; then\n    source "$HOME/.liquidprompt/liquidprompt"\nfi' >> ~/.bashrc && source ~/.bashrc
```

Run this in your terminal — it will install Git, clone Liquidprompt, update your `~/.bashrc`, and reload your shell environment.


---


That happens because `PROMPT_COMMAND` set this way only persists for the current session when sourced, but does not get evaluated freshly on each new shell login after a reboot.

Instead, you should place the actual code to set `PROMPT_COMMAND` *without* expansion into your `~/.bashrc`.

Here is what you should add exactly to `~/.bashrc`:

```bash
PROMPT_COMMAND='PS1="\[\e[1;33m\]$(date +"%F %T")\[\e[0m\]\n\[\e[1;32m\]\w | \u\[\e[0m\] "'
```

Then, every new shell session (including after reboot) will evaluate it and set the prompt dynamically. Make sure not to expand `$(date ...)` while writing to the file, or else it will insert a static date/time. Let me know if you want me to craft the precise `echo` command to append this safely!
---
