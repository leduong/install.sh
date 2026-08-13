SHELL := /bin/bash

commit:
	git commit -m "🍻 Updated at `date`"

fail2ban-status:
	sudo fail2ban-client status

# usage: make fail2ban-status-jail JAIL=sshd
fail2ban-status-jail:
	@if [ -z "$(JAIL)" ]; then echo "Usage: make fail2ban-status-jail JAIL=sshd"; exit 1; fi
	sudo fail2ban-client status $(JAIL)

# usage: make fail2ban-unban IP=1.2.3.4
fail2ban-unban:
	@if [ -z "$(IP)" ]; then echo "Usage: make fail2ban-unban IP=1.2.3.4"; exit 1; fi
	sudo fail2ban-client unban $(IP)

fail2ban-unban-all:
	sudo fail2ban-client unban --all

# clean log and cache on Ubuntu/Debian
clean-system:
	sudo journalctl --vacuum-time=3d
	sudo apt clean
	sudo apt autoremove -y
	sudo find /var/log -type f -name "*.gz" -delete
	sudo find /var/log -type f -regex ".*\.[0-9]+" -delete
	sudo truncate -s 0 /var/log/*.log 2>/dev/null || true
	rm -rf ~/.cache/*
