#!/usr/bin/env make -f

TOPDIR := $(realpath $(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
SELF := $(abspath $(lastword $(MAKEFILE_LIST)))

OS := $(shell uname -s | tr '[:upper:]' '[:lower:]')
OSARCH := $(shell uname -m)
VMNETS := $(shell find "/Library/Preferences/VMware Fusion/" -type d -maxdepth 1 -name "vmnet*" -exec basename {} \;)
VMNETS_RANDOMIZED := $(shell for w in $(VMNETS); do echo $$w; done | sort -R)

VMWARE_GUI ?= false

.PHONY: help
help: ## Show help message (list targets)
	@awk 'BEGIN {FS = ":.*##"; printf "\nTargets:\n"} /^[$$()% 0-9a-zA-Z_-]+:.*?##/ {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}' $(SELF)

SHOW_ENV_VARS = \
	OS \
	OSARCH \
	VMNETS \
	VMWARE_GUI

show-var-%:
	@{ \
	escaped_v="$(subst ",\",$($*))" ; \
	if [ -n "$$escaped_v" ]; then v="$$escaped_v"; else v="(undefined)"; fi; \
	printf "%-15s %s\n" "$*" "$$v"; \
	}

.PHONY: show-env
show-env: $(addprefix show-var-, $(SHOW_ENV_VARS)) ## Show environment details

.PHONY: show-netconf
show-netconf: ## Show VMware networking configuration
	@{ \
	set -x ; \
	cat "/Library/Preferences/VMware Fusion/networking" ; \
	vmrun listHostNetworks ; \
	}

show-vmnet%-dhcp: ## Show DHCP config for a given vmnet
	@cat "/Library/Preferences/VMware Fusion/vmnet$*/dhcpd.conf"

show-vmnet%-nat: ## Show NAT config for a given vmnet
	@cat "/Library/Preferences/VMware Fusion/vmnet$*/nat.conf"

show-vmnet%-leases: ## Show lease table for a given vmnet
	@cat /var/db/vmware/vmnet-dhcpd-vmnet$*.leases

get-ip-from-vmnet%: ## Find control IP in a given vmnet
	@{ \
	set -e ; \
	range="$$($(MAKE) -f $(SELF) show-vmnet$*-dhcp | grep range | awk '{print $$2}')" ; \
	net="$${range%.*}" ; \
	last_octet="$${range##*.}" ; \
	if [ 10 -lt "$${last_octet}" ]; then printf "%s.10\n" "$${net}"; fi; \
	}

.PHONY: get-ip
get-ip: ## Find control IP in any of existing vmnets (pick one from randomized order of vmnets)
	@{ \
	set -e ; \
	for vmnet in $(VMNETS_RANDOMIZED); do res=$$($(MAKE) -f $(SELF) get-ip-from-$${vmnet}); if [ -n "$$res" ]; then echo $$res; break; fi; done; \
	}

.PHONY: state-env
state-env:
	if [ ! -f state.env ]; then \
		echo "export CONTROL_IP=$$($(MAKE) -f $(SELF) get-ip)" >state.env ; \
		echo "export VMWARE_GUI=$(VMWARE_GUI)" >>state.env ; \
		. ./state.env && echo "Selected CONTROL_IP: $$CONTROL_IP" ; \
	else \
		. ./state.env && echo "WARNING: reusing CONTROL_IP from state.env ($$CONTROL_IP)" >&2 ; \
	fi

state-env-from-vmnet%:
	if [ ! -f state.env ]; then \
		echo "export CONTROL_IP=$$($(MAKE) -f $(SELF) get-ip-from-vmnet$*)" >state.env ; \
		echo "export VMWARE_GUI=$(VMWARE_GUI)" >>state.env ; \
		. ./state.env && echo "Selected CONTROL_IP: $$CONTROL_IP" ; \
	else \
		. ./state.env && echo "WARNING: reusing CONTROL_IP from state.env ($$CONTROL_IP)" >&2 ; \
	fi

up-from-vmnet%: state-env-from-vmnet% ## Create k8s cluster with control and worker IPs from a given vmnet
	. ./state.env && vagrant up

.PHONY: up
up: state-env ## Create k8s cluster with control and worker IPs from a random vmnet
	. ./state.env && vagrant up

.PHONY: status
status: ## Show node VMs status via "vagrant status"
	. ./state.env && vagrant status

.PHONY: status-vmrun
status-vmrun: ## Show node VMs status via "vmrun"
	./vm-helpers/status-vmrun.sh

.PHONY: reboot
reboot: ## Reboot node VMs via "vagrant reload" (most graceful way)
	. ./state.env && ./vm-helpers/reboot-vagrant.sh

.PHONY: reboot-forced
reboot-forced: ## Reboot node VMs via "vagrant reload --force" (less graceful way)
	. ./state.env && ./vm-helpers/reboot-vagrant.sh --force

.PHONY: reset
reset: ## Reset node VMs via "vmrun reset" (not graceful at all, beware)
	./vm-helpers/reset-vmrun.sh

.PHONY: stop
stop: ## Stop node VMs
	vagrant halt

.PHONY: down
down: ## Destroy node VMs
	vagrant destroy -f
	rm -rf configs/
	rm -f state.env

clean: down
	rm -rf $(TOPDIR)/.vagrant
