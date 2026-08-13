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
