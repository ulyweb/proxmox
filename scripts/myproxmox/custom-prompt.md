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
